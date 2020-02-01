# get_instance_json_by_name: retrieve the aws cli json for a specific instance
function get_instance_json_by_name() {
    local function_name="get_instance_json_by_name" instance_name vpc_id vpc_name target_variable_name vpc_id;
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name;
    check_required_argument $function_name vpc_id vpc_name;

    local _get_instance_json_by_name="$vpc_id";
    [[ -z "$_get_instance_json_by_name" ]] && get_vpc_id --vpc_name "$vpc_name" --target_variable_name "_get_instance_json_by_name";

    log_debug "Retrieving instance '$instance_name' from VPC '$_get_instance_json_by_name'.";
    _get_instance_json_by_name="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" "Name=vpc-id,Values=$_get_instance_json_by_name")";
    _get_instance_json_by_name="$(echo "$_get_instance_json_by_name" | jq -r '.Reservations[0] .Instances[0]')";
    eval "$target_variable_name='$_get_instance_json_by_name'";
}

# get_instance_private_ip: Get the private ip address of the instance with name '$instance_name' in vpc with id '$vpc_id'
function get_instance_private_ip() {
    local function_name="get_instance_private_ip" instance_name vpc_id vpc_name target_variable_name tmp_instance_json;
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name;
    local _get_instance_private_ip;
    log_info "Retrieving the private ip of instance '$instance_name' in VPC $vpc_id $vpc_name.";
    get_instance_json_by_name --instance_name "$instance_name" --vpc_id "$vpc_id" --vpc_name "$vpc_name" \
        --target_variable_name _get_instance_private_ip;
    _get_instance_private_ip="$(echo "$_get_instance_private_ip" | jq -r '.PrivateIpAddress')";
    [[ "" == "null" ]] && _get_instance_private_ip="";
    eval "$target_variable_name='$_get_instance_private_ip'";
}

# get_instance_public_dns: Get the public dns address of the instance with name '$instance_name' in vpc with id '$vpc_id'
function get_instance_public_dns() {
    local function_name="get_instance_public_dns" instance_name vpc_id vpc_name target_variable_name tmp_instance_json;
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name;
    check_required_argument $function_name vpc_id vpc_name
    log_info "Retrieving public DNS entry for instance '$instance_name' in VPC '${vpc_id}${vpc_name}'.";
    local _get_instance_public_dns;
    get_instance_json_by_name --instance_name "$instance_name" --vpc_id "$vpc_id" --vpc_name "$vpc_name" \
        --target_variable_name _get_instance_public_dns;
    _get_instance_public_dns="$(echo "$_get_instance_public_dns" | jq -r '.PublicDnsName')";
    [[ "$_get_instance_public_dns" == "null" ]] && _get_instance_public_dns="";

    eval "$target_variable_name='$_get_instance_public_dns'";
}

# get_ami: retrieve the ami with the specified name or prefix
function get_ami() {
    local function_name="get_ami" ami_name ami_name_prefix owners="self" target_variable_name;
    import_args "$@";
    check_required_argument "$function_name" ami_name ami_name_prefix target_variable_name;

    if [ -n "$ami_name" -a -n "$ami_name_prefix" ]; then
        log_fatal "Either ami_name or ami_name_prefix should be past to function $function_name, not both.";
    fi;

    if [ -n "$ami_name" ]; then
        local name_filter="Name=name,Values=$ami_name";
    else
        local name_filter="Name=name,Values=$ami_name_prefix"'*';
    fi;
    log_info "Retrieving AMI through filter '$name_filter'.";
    local _get_ami="$(aws ec2 describe-images --owners $owners --filters "$name_filter" "Name=state,Values=available")";
    _get_ami="$(echo "$_get_ami" | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')";
    eval "$target_variable_name='$_get_ami'";
}

function get_security_group_id() {
    local function_name="get_security_group_id" security_group_name vpc_id target_variable_name tmp_security_group_id;
    import_args "$@";
    check_required_arguments "$function_name" security_group_name target_variable_name;
    check_required_argument $function_name vpc_id vpc_name;

    local _get_security_group_id="$vpc_id";
    [[ -z "$_get_security_group_id" ]] && get_vpc_id --vpc_name "$vpc_name" --target_variable_name "_get_security_group_id";

    log_info "Retrieving security group id for $security_group_name.";

    local _get_security_group_id="$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$security_group_name" "Name=vpc-id,Values=$vpc_id")";
    _get_security_group_id="$(echo "$_get_security_group_id" | jq -r '.SecurityGroups[0].GroupId')";
    [[ "$_get_security_group_id" == "null" ]] && _get_security_group_id="";
    eval "$target_variable_name='$_get_security_group_id'";
}

function get_bastion_ssh_config() {
  local function_name="get_bastion_ssh_config" vpc_id vpc_name bastion_name bastion_private_key_file ssh_username target_variable_name;
  import_args "$@";
  check_required_arguments "$function_name" bastion_name bastion_private_key_file ssh_username target_variable_name;
  check_required_argument $function_name vpc_id vpc_name;

  local _get_bastion_ssh_config_vpc_id="$vpc_id";
  [[ -z "$_get_bastion_ssh_config_vpc_id" ]] && get_vpc_id --vpc_name "$vpc_name" \
        --target_variable_name "_get_bastion_ssh_config_vpc_id" --fail_if_not_found "false";

	local _get_bastion_ssh_config
	if [ -n "$_get_bastion_ssh_config_vpc_id" ]; then
      local _bastion_dns="";
      get_instance_public_dns --vpc_id "$_get_bastion_ssh_config_vpc_id" --instance_name "$bastion_name" --target_variable_name _bastion_dns;
      [[ -z "$_bastion_dns" ]] && log_warn "Bastion host '$bastion_name' not found in VPC '$_get_bastion_ssh_config_vpc_id'." && return;
      local _get_bastion_ssh_config=$(cat << EOF
Host $bastion_name
    Hostname $_bastion_dns
    User $ssh_username
    IdentityFile "$bastion_private_key_file"
EOF
);
  fi;
	eval "$target_variable_name='$_get_bastion_ssh_config'";
}