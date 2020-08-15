TERRAFORM_TEMP_DIR="/tmp/terraform";
export TF_VAR_TERRAFORM_TEMP_DIR="${D}TERRAFORM_TEMP_DIR"
mkdir -p "${D}TERRAFORM_TEMP_DIR";
cp -R . "${D}TERRAFORM_TEMP_DIR";
#foreach ($terraformInstance in $instance.getInstancesByFileExtensions(".tf", ".tpl", ".tfvars"))
dir="$terraformInstance.getRelativePath()";
cd ../../../${D}dir;
if [ -f "init.sh" ]; then
    log_info "Sourcing init.sh in ${D}dir";
    . ./init.sh;
fi;
log_info 'Copying *.tf, *.tpl, *.tfvars and after_terraform_apply* files from instance "$terraformInstance.toString()"';
tmp_instance_guid="$terraformInstance.getGuid()";
#[[
for f in $(find . -maxdepth 1 -type f -name \*.tf); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f as '$TERRAFORM_TEMP_DIR/${tmp_instance_guid}_$f'.";
    cp $f "$TERRAFORM_TEMP_DIR/${tmp_instance_guid}_$f";
done;

for f in $(find . -maxdepth 1 -type f -name \*.tpl); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f from ../../../$dir";
    cp $f "$TERRAFORM_TEMP_DIR";
done;

for f in $(find . -maxdepth 1 -type f -name \*.tfvars); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f from ../../../$dir";
    cp $f "$TERRAFORM_TEMP_DIR";
done;

for f in $(find . -maxdepth 1 -type f -name after_terraform_\*); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f from ../../../$dir";
    cp $f "$TERRAFORM_TEMP_DIR";
done;
]]#
#end

#set ($confirmInstances = $instance.getInstancesByPacketType("TERRAFORM-CONFIRM"))
#set ($confirmApply = "false")
#set ($confirmDestroy = "false" )
#if ($confirmInstances.size() > 0)

function terraform_request_apply_confirmations() {
	#foreach ($confirmInstance in $confirmInstances)
		#if ($confirmInstance.getAttribute("confirm_apply") == "1")
			#set ($confirmApply = "true")
			
	cd "${D}ENVIRONMENTS_ROOT/$confirmInstance.getRelativePath()";
	. ./$confirmInstance.getAttribute("confirmation_file");
		#end
	#end
	
}	

function terraform_request_destroy_confirmations() {
	#foreach ($confirmInstance in $confirmInstances)
		#if ($confirmInstance.getAttribute("confirm_destroy") == "1")
			#set ($confirmDestroy = "true")
			
	cd "${D}ENVIRONMENTS_ROOT/$confirmInstance.getRelativePath()";
	. ./$confirmInstance.getAttribute("confirmation_file");
		#end
	#end
	
}
#end

export TERRAFORM_EXTERNAL_APPLY_CONFIRMATIONS_REQUIRED="$confirmApply";
export TERRAFORM_EXTERNAL_DESTROY_CONFIRMATIONS_REQUIRED="$confirmDestroy";

cd "${D}INSTANCE_DIR";
if [ -f "init.sh" ]; then
    log_info "Sourcing init.sh in ${D}INSTANCE_DIR";
    . ./init.sh;
fi;
