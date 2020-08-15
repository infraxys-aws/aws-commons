#if ($instance.getAttribute("aws_provider_version") != "")
terraform {
  required_providers {
    aws = "$instance.getAttribute("aws_provider_version")"
    template = "~> 2.1"
  }
}

provider "aws" {
  region = "$instance.getAttribute("aws_region")"
}
#end

#if ($extra_terraform)
$extra_terraform
#end

#set ($childStateInstances = $instance.getInstancesByPacketType(false, "TERRAFORM-STATE"))
#if ($childStateInstances.size() == 0)
	$environment.throwException("No instance of packet type 'TERRAFORM-STATE' found under this Terraform runner instance.")
#end

#foreach ($stateInstance in $instance.getInstancesByAttributeVelocityNames("state_velocity_names", false, true))
#if ($stateInstance.hasPacketType("TERRAFORM-STATE"))
#set ($stateInstanceFound = true)
data "terraform_remote_state" "$stateInstance.getAttribute("state_name")" {
backend = "s3"
config = {
bucket = "$stateInstance.getAttribute("state_s3_bucket")"
key = "$stateInstance.getAttribute("state_key")"
region = "$stateInstance.getAttribute("state_aws_region")"
profile = "$stateInstance.getAttribute("state_profile")"
}
}

#else
	#set ($message = "Terraform state instance key '" + $stateInstance.packetType + "' not supported")
	$environment.throwException($message)
#end
#end


