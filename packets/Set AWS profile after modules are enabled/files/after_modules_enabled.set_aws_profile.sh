#set ($tmpAwsProfile = $instance.getAttribute("aws_profile"))
#if ($tmpAwsProfile != "")
set_aws_profile --profile_name "$tmpAwsProfile";
#end