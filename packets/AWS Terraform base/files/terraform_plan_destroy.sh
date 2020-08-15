#if ($instance.getParentInstanceByAttributeValue("skip_terraform_action_creation", "1", false))
	#set ($skip_action_creation = true)
#end

#[[
cd "$TERRAFORM_TEMP_DIR";
terraform_plan --destroy "true";
]]#