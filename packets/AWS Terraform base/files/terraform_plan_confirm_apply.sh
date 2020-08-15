#if ($instance.getParentInstanceByAttributeValue("skip_terraform_action_creation", "1", false))
	#set ($skip_action_creation = true)
#end

#[[
cd "$TERRAFORM_TEMP_DIR";

terraform_plan_confirm_apply $confirm_email_argument $confirm_email_tpl_file_argument;
]]#