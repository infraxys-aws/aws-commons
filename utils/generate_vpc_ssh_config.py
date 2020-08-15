#!/usr/bin/env python3.7

import json
import sys

import boto3


class SshGenerator(object):

    def __init__(self, vpc_id=None, vpc_name=None, name_list_json_file=None):
        self.vpc_id = vpc_id
        self.vpc_name = vpc_name
        self.name_list_json_file = name_list_json_file
        self.ssh_key_names_file = '/tmp/ssh_key_names.json'
        self.ec2 = boto3.client('ec2')
        self.result = ""

    def generate_config(self):
        self.get_vpc()

        if not self.vpc_id:
            print(
                "VPC '" + self.vpc_name + "' not found. This is not necessarily a problem because it might not have been created yet.")
            return ""

        instances_json = self.get_instances(vpc_id=self.vpc_id)
        non_bastion_instances = []
        multi_instance_names = []
        instance_names = []
        bastion_instance = None
        bastion_name = ""
        nat_bastion_instance = None
        nat_bastion_name = ""
        instance_details_json = {}
        ssh_keys_by_instance_name = {}
        for reservation in instances_json['Reservations']:
            for instance in reservation['Instances']:
                instance_name = self.get_name_tag_value(instance)
                if not instance_name or ' ' in instance_name:  # ignore instances that don't have a name tag value or a value with spaces
                    continue

                if not "KeyName" in instance:
                    continue

                if not instance_name in ssh_keys_by_instance_name:
                    ssh_keys_by_instance_name[instance_name] = '{}.pem'.format(instance["KeyName"])

                if "nat-" in instance_name.lower() and instance["PublicDnsName"] != "":
                    nat_bastion_instance = instance
                    nat_bastion_name = instance_name

                if "bastion" in instance_name.lower():
                    bastion_instance = instance
                    bastion_name = instance_name
                    instance_details_json[instance_name] = []
                    instance_details_json[instance_name].append(self.get_instance_details(bastion_name, instance))
                else:
                    if instance_name in instance_names:
                        multi_instance_names.append(instance_name)
                    else:
                        instance_details_json[instance_name] = []

                    instance_names.append(instance_name)
                    non_bastion_instances.append(instance)

        if not bastion_instance:
            if nat_bastion_instance: # use this as an alternative ...
                bastion_instance = nat_bastion_instance
                bastion_name = nat_bastion_name
                non_bastion_instances.remove(bastion_instance)
            else:
                raise Exception("No instance with 'bastion' in the 'Name'-tag found in this vpc.")


        key_filename = "~/.ssh/keys/{}.pem".format(bastion_instance["KeyName"])
        instance_counter = {}

        self.result = """Host {}
    Hostname {}
    User ec2-user
    IdentityFile "{}"                    
                    """.format(bastion_name, bastion_instance["PublicDnsName"], key_filename)

        proxy_command = 'ProxyCommand ssh {} -W %h:%p'.format(bastion_name)
        for instance in non_bastion_instances:
            key_filename = "~/.ssh/keys/{}.pem".format(instance["KeyName"])
            instance_name = self.get_name_tag_value(instance)
            real_instance_name = instance_name
            if instance_name in multi_instance_names:
                if instance_name in instance_counter.keys():
                    counter = instance_counter[instance_name] + 1
                else:
                    counter = 1

                instance_counter[instance_name] = counter
                instance_name = "{}-{}".format(instance_name, counter)

            #print("Adding {} to {}".format(instance_name, real_instance_name))

            instance_details_json[real_instance_name].append(
                self.get_instance_details(instance_name, instance))
            instance_private_ip = instance["PrivateIpAddress"]

            self.result = """{}
       
Host {}
   Hostname {}
   User ubuntu
   {}
   IdentityFile {}
            """.format(self.result, instance_name, instance_private_ip, proxy_command, key_filename)

        if self.name_list_json_file:
            with open(self.name_list_json_file, 'w', encoding='utf-8') as f:
                json.dump(instance_details_json, f, ensure_ascii=False, indent=2)

        with open(self.ssh_key_names_file, 'w', encoding='utf-8') as f:
            json.dump(ssh_keys_by_instance_name, f, ensure_ascii=False, indent=2)

        return self.result

    def get_instance_details(self, bastion_name, instance):
        jsonObject = {
            'hostname': bastion_name,
            'privateIpAddress': instance['PrivateIpAddress'],
            'keyName': instance['KeyName']
        }
        return jsonObject

    def get_vpc(self):
        if not self.vpc_id:
            if not self.vpc_name:
                raise Exception("vpc_id nor vpc_name set.")

            self.vpc_id = self.get_vpc_id(vpc_name=self.vpc_name)

    def get_vpc_id(self, vpc_name):
        json = self.ec2.describe_vpcs(Filters=[{
            'Name': 'tag:Name',
            'Values': [vpc_name]
        }])
        if len(json['Vpcs']) == 0:
            return None

        vpc_json = json['Vpcs'][0]

        return vpc_json['VpcId']

    def get_instances(self, vpc_id):
        instances_json = self.ec2.describe_instances(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]}
            ]
        )
        return instances_json

    def get_name_tag_value(self, json_object):
        if "Tags" in json_object:
            for tag in json_object["Tags"]:
                if tag["Key"].lower() == "name":
                    return tag["Value"]

        return None


if __name__ == "__main__":
    vpc_name = sys.argv[1]
    name_list_json_file = None
    if len(sys.argv) > 2:
        name_list_json_file = sys.argv[2]

    generator = SshGenerator(vpc_name=vpc_name, name_list_json_file=name_list_json_file)
    result = generator.generate_config()
    print(result)
