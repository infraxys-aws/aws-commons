#!/usr/bin/env python3.7

import sys

import boto3


class SshGenerator(object):

    def __init__(self, vpc_id=None, vpc_name=None):
        self.vpc_id = vpc_id
        self.vpc_name = vpc_name
        self.ec2 = boto3.client('ec2')
        self.result = ""

    def generate_config(self):
        self.get_vpc()

        if not self.vpc_id:
            print("VPC not found. This is not necessarily a problem because it might not have been created yet.")
            return ""

        instances_json = self.get_instances(vpc_id=self.vpc_id)
        non_bastion_instances = []
        multi_instance_names = []
        instance_names = []
        bastion_instance = None
        bastion_name = ""
        for reservation in instances_json['Reservations']:
            for instance in reservation['Instances']:
                instance_name = self.get_name_tag_value(instance)
                if not instance_name:  # ignore instances that don't have a name tag value
                    continue

                if not "KeyName" in instance:
                    continue

                if "bastion" in instance_name.lower():
                    bastion_instance = instance
                    bastion_name = instance_name
                else:
                    if instance_name in instance_names:
                        multi_instance_names.append(instance_name)

                    instance_names.append(instance_name)
                    non_bastion_instances.append(instance)

        if not bastion_instance:
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
            if instance_name in multi_instance_names:
                if instance_name in instance_counter.keys():
                    counter = instance_counter[instance_name] + 1
                else:
                    counter = 1

                instance_counter[instance_name] = counter
                instance_name = "{}-{}".format(instance_name, counter)

            instance_private_ip = instance["PrivateIpAddress"]

            self.result = """{}
       
Host {}
   Hostname {}
   User ubuntu
   {}
   IdentityFile {}
            """.format(self.result, instance_name, instance_private_ip, proxy_command, key_filename)

        return self.result

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
        for tag in json_object["Tags"]:
            if tag["Key"].lower() == "name":
                return tag["Value"]

        return None


if __name__ == "__main__":
    vpc_name = sys.argv[1]
    generator = SshGenerator(vpc_name=vpc_name)
    result = generator.generate_config()
    print(result)
