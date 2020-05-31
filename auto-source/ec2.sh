# get_instance_json_by_name: retrieve the aws cli json for a specific instance
function get_instance_json_by_name() {
    local function_name="get_instance_json_by_name" instance_name vpc_id vpc_name target_variable_name vpc_id \
          region="$aws_region";
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name region;
    check_required_argument $function_name vpc_id vpc_name;

    local _get_instance_json_by_name="$vpc_id";
    [[ -z "$_get_instance_json_by_name" ]] && get_vpc_id --region "$region" --vpc_name "$vpc_name" \
          --target_variable_name "_get_instance_json_by_name" --fail_if_not_found "false";

    if [ -n "$_get_instance_json_by_name" ]; then
      log_debug "Retrieving instance '$instance_name' from VPC '$_get_instance_json_by_name' in '$region'.";
      _get_instance_json_by_name="$(aws ec2 describe-instances --region "$region" --filters "Name=tag:Name,Values=$instance_name" "Name=vpc-id,Values=$_get_instance_json_by_name")";
      _get_instance_json_by_name="$(echo "$_get_instance_json_by_name" | jq -r '.Reservations[0] .Instances[0]')";
    fi;
    eval "$target_variable_name='$_get_instance_json_by_name'";
}

# get_instance_private_ip: Get the private ip address of the instance with name '$instance_name' in vpc with id '$vpc_id'
function get_instance_private_ip() {
    local function_name="get_instance_private_ip" instance_name vpc_id vpc_name target_variable_name tmp_instance_json \
          region="$aws_region";
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name region;
    local _get_instance_private_ip;
    log_info "Retrieving the private ip of instance '$instance_name' in VPC $vpc_id $vpc_name.";
    get_instance_json_by_name --instance_name "$instance_name" --region "$region" --vpc_id "$vpc_id" --vpc_name "$vpc_name" \
        --target_variable_name _get_instance_private_ip;
    _get_instance_private_ip="$(echo "$_get_instance_private_ip" | jq -r '.PrivateIpAddress')";
    [[ "$_get_instance_private_ip" == "null" ]] && _get_instance_private_ip="";
    eval "$target_variable_name='$_get_instance_private_ip'";
}

# get_instance_public_dns: Get the public dns address of the instance with name '$instance_name' in vpc with id '$vpc_id'
function get_instance_public_dns() {
    local function_name="get_instance_public_dns" instance_name vpc_id vpc_name target_variable_name tmp_instance_json \
        region="$aws_region" fail_if_not_found="true";
    import_args "$@";
    check_required_arguments $function_name instance_name target_variable_name region;
    check_required_argument $function_name vpc_id vpc_name
    log_info "Retrieving public DNS entry for instance '$instance_name' in VPC '${vpc_id}${vpc_name}'.";
    local _get_instance_public_dns;
    get_instance_json_by_name --instance_name "$instance_name" --region "$region" --vpc_id "$vpc_id" --vpc_name "$vpc_name" \
        --target_variable_name _get_instance_public_dns;
    _get_instance_public_dns="$(echo "$_get_instance_public_dns" | jq -r '.PublicDnsName')";
    [[ "$_get_instance_public_dns" == "null" ]] && _get_instance_public_dns="";
    if [ -z "$_get_instance_public_dns" ]; then
        if [ "$fail_if_not_found" == "true" ]; then
          log_fatal "No instance with name '$instance_name' found.";
        else
          log_info "No instance with name '$instance_name' found.";
        fi;
    fi;
    eval "$target_variable_name='$_get_instance_public_dns'";
}

# get_ami: retrieve the ami with the specified name or prefix
function get_ami() {
    local function_name="get_ami" ami_name ami_name_prefix owners="self" executable_users="self" target_variable_name region="$aws_region";
    import_args "$@";
    check_required_arguments "$function_name" target_variable_name region;
    check_required_argument "$function_name" ami_name ami_name_prefix target_variable_name;

    if [ -n "$ami_name" -a -n "$ami_name_prefix" ]; then
        log_fatal "Either ami_name or ami_name_prefix should be past to function $function_name, not both.";
    fi;

    if [ -n "$ami_name" ]; then
        local name_filter="Name=name,Values=$ami_name";
    else
        local name_filter="Name=name,Values=$ami_name_prefix";
    fi;
    local owners_option="";
    local executable_users_option="";
    if [ -n "$executable_users" -a "$executable_users" != "self" ]; then
      executable_users_option="--executable-users $executable_users";
    else
      owners_option="--owners $owners";
    fi;
    log_info "Retrieving latest AMI through filter '$name_filter' and owners-option '$owners_option'.";
    local _get_ami="$(aws ec2 describe-images --region "$region" $owners_option \
            --filters "$name_filter" "Name=state,Values=available" \
            $executable_users_option)";
    _get_ami="$(echo "$_get_ami" | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')";

    if [ "$_get_ami" == "-null-" -o "$_get_ami" == "null" ]; then
      _get_ami="";
    fi;
    eval "$target_variable_name='$_get_ami'";
}

function get_security_group_id() {
    local function_name="get_security_group_id" security_group_name vpc_id target_variable_name tmp_security_group_id \
        region="$aws_region";
    import_args "$@";
    check_required_arguments "$function_name" security_group_name target_variable_name region;
    check_required_argument $function_name vpc_id vpc_name;

    local _get_security_group_id="$vpc_id";
    [[ -z "$_get_security_group_id" ]] && get_vpc_id --region "$region" --vpc_name "$vpc_name" --target_variable_name "_get_security_group_id";

    log_info "Retrieving security group id for $security_group_name.";

    local _get_security_group_id="$(aws ec2 describe-security-groups --region "$region" --filters "Name=group-name,Values=$security_group_name" "Name=vpc-id,Values=$vpc_id")";
    _get_security_group_id="$(echo "$_get_security_group_id" | jq -r '.SecurityGroups[0].GroupId')";
    [[ "$_get_security_group_id" == "null" ]] && _get_security_group_id="";
    eval "$target_variable_name='$_get_security_group_id'";
}

function get_bastion_ssh_config() {
  local function_name="get_bastion_ssh_config" vpc_id vpc_name bastion_name bastion_private_key_file ssh_username \
          region="$aws_region" target_variable_name fail_if_not_found="true";
  import_args "$@";
  check_required_arguments "$function_name" bastion_name bastion_private_key_file ssh_username target_variable_name region;
  check_required_argument $function_name vpc_id vpc_name;

  local _get_bastion_ssh_config_vpc_id="$vpc_id";
  [[ -z "$_get_bastion_ssh_config_vpc_id" ]] && get_vpc_id --region "$region" --vpc_name "$vpc_name" \
        --target_variable_name "_get_bastion_ssh_config_vpc_id" --fail_if_not_found "false";

	local _get_bastion_ssh_config
	if [ -n "$_get_bastion_ssh_config_vpc_id" ]; then
      local _bastion_dns="";
      get_instance_public_dns --region "$region" --vpc_id "$_get_bastion_ssh_config_vpc_id" \
          --instance_name "$bastion_name" --target_variable_name _bastion_dns --fail_if_not_found "$fail_if_not_found";
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