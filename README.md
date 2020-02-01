# AWS Core Infraxys module

## Introduction

This module contains some helper functions and packets for base AWS functionality.

## Requirements

### AWS Credentials

To use this module, AWS credentials should be configured.
If the provisioning server is running in AWS, then the instance profile can be used. Select "IAM_ROLE" in this case.

Define a profile if you're not using the instance profile.
All available Infraxys variables of type "AWS-CREDENTIALS" and "AWS-CONFIG" are automatically appended to ~/.aws/credentials and ~/.aws/config in the Docker container on the provisioning server where your code runs.

You can create one variable with multiple profiles or separate variables with one or more profiles in each. This can be done at several levels in the project tree.
See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html for more information.
 
#### AWS-CREDENTIALS

Create a variable and enter "AWS-CREDENTIALS" as its type. Give it a name that's unique for "AWS-CREDENTIALS"-variables.

Example value:  
```text
[my-aws-profile]
aws_access_key_id = AK...
aws_secret_access_key = tye...
region = eu-west-1
```

#### AWS-CONFIG
Example variable for AWS access. "role_arn" and "mfa_serial" are optional.

```text
[profile default]
region = eu-west-1

[profile my-us-west-1-role]
region = us-west-1
role_arn = arn:aws:iam::...
source_profile = my-aws-profile
mfa_serial = arn:aws:iam::...
```
 
## Packets

### AWS Core variables

This packet contains attributes that are used by the other packets and by the roles.
 
#### Usage
 
Create an instance of this packet on every container that contains other packets that need AWS access.
 
### AWS tags

Specify one or more tags for AWS resources and re-use this in other instances.

#### Usage

AWS resource instances that have tags can reuse the value of this instance. 
This ensures that all taggable resources have the same tags.

## Bash functions

### EC2 

- get_instance_json_by_name
- get_instance_private_ip
- get_ami
- get_security_group_id

### VPC

- get_vpc
- get_vpc_id
- get_subnet_id

### Route53

- get_zone_id_by_name