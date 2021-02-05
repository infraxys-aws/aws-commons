export PYTHONPATH="$(pwd)/python:$PYTHONPATH";

function generate_ssh_config_for_vpc() {
    local function_name="generate_ssh_config_for_vpc" vpc_name name_list_json_file="/tmp/servers.json";
    import_args "$@";
    check_required_arguments "$function_name" vpc_name;
    log_info "Generating SSH configuration for VPC $vpc_name into ~/.ssh/generated.d/$vpc_name.";

    local _ssh_config="$("$AWS_COMMONS_MODULE_DIR/python/infraxys_aws/utils/generate_vpc_ssh_config.py" "$vpc_name" "$name_list_json_file")";
    if [ $? -eq 0 -a "$_ssh_config" != "" ]; then
        log_info "SSH config generated.";
        echo "$_ssh_config" > ~/.ssh/generated.d/$vpc_name;
        if [ -d "/host/.ssh/infraxys" ]; then
            local host_filename="/host/.ssh/infraxys/config.d/$vpc_name";
            log_info "Storing SSH config in hosts file $host_filename";
            mkdir -p "/host/.ssh/infraxys/config.d";
            echo "$_ssh_config" > $host_filename;
        fi;
        cat ~/.ssh/generated.d/$vpc_name
    else
        log_error "Unable to generate ssh config for vpc '$vpc_name'.";
    fi;
}

function cache_ssh_config_in_project() {
	local vpc_name aws_profile vault_config_variable;
	import_args "$@";
	check_required_arguments "cache_ssh_config_in_project" vpc_name aws_profile vault_config_variable;
	
	mkdir -p /cache/project/.ssh/keys;
	mkdir -p /cache/project/.ssh/config.d;	
	
	set_aws_profile --profile_name "$aws_profile";
	generate_ssh_config_for_vpc --vpc_name "$vpc_name";
	get_ssh_keys_from_vault --vault_config_variable "$vault_config_variable";
	
	cp ~/.ssh/keys/* /cache/project/.ssh/keys;
	cp ~/.ssh/generated.d/$vpc_name /cache/project/.ssh/config.d/;
}	

