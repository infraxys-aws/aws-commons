
# Get the json for the vpc with tag Name=<value of variable 'vpc_name'>.
#   if the <vpc_name> was already retrieved, then get the json from the cached variable
#   otherwise get the json using the AWS CLI and cache the result
# Call this function with argument 'target_variable_name' to avoid the need of running it in a sub-shell.
function get_vpc() {
    local function_name="get_vpc" vpc_name target_variable_name vpc_json fail_if_not_found="true";
    import_args "$@";
    check_required_arguments $function_name vpc_name target_variable_name;

    cache_variable_name="vpc_json_${vpc_name//[-.]/_}";
    local cached_value="${!cache_variable_name}";

    if [ -n "$cached_value" ]; then
        local _get_vpc="$cached_value";
        log_debug "Retrieved VPC config for '$vpc_name' from cache.";
    else
        log_info "Retrieving VPC ID for VPC '$vpc_name'.";
        local _get_vpc="$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpc_name" | jq -r ".Vpcs[0]")";
        [[ "$_get_vpc" == "null" ]] && _get_vpc="";
    fi;

    if [ -z "$_get_vpc" -a "$fail_if_not_found" == "true" ]; then
        log_fatal "No VPC with name $vpc_name found. This is normal in case the environment was not yet created.";
    fi;
    eval "$cache_variable_name='$_get_vpc'";
    eval "$target_variable_name='$_get_vpc'";
}

# Get the vpc_id for VPC <vpc_name> using function get_vpc()
# Call this function with argument 'target_variable_name' to avoid the need of running it in a sub-shell.
function get_vpc_id() {
    local function_name="get_vpc_id" vpc_name target_variable_name temp_var fail_if_not_found="true";
    import_args "$@";
    check_required_arguments $function_name vpc_name target_variable_name;

    local _get_vpc_id;
    get_vpc --vpc_name "$vpc_name" --target_variable_name "_get_vpc_id" --fail_if_not_found "$fail_if_not_found";

    _get_vpc_id="$(echo "$_get_vpc_id" | jq -r ".VpcId")";
    [[ "$_get_vpc_id" == "null" ]] && _get_vpc_id="";

    eval "$target_variable_name='$_get_vpc_id'";
}

function get_subnet_id() {
    local function_name="get_subnet_id" subnet_name target_variable_name vpc_id vpc_name fail_if_not_found="true" tmp_subnet_id;
    import_args "$@";
    check_required_arguments "$function_name" subnet_name target_variable_name;
    check_required_argument "$function_name" vpc_id vpc_name;

    local _get_subnet_id="$vpc_id";
    [[ -z "$_get_subnet_id" ]] && get_vpc_id --vpc_name "$vpc_name" --target_variable_name _get_subnet_id;

    _get_subnet_id="$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnet_name" "Name=vpc-id,Values=$_get_subnet_id")";
    _get_subnet_id="$(echo "$_get_subnet_id" | jq -r '.Subnets[0].SubnetId')";

    [[ "$_get_subnet_id" == "null" ]] && _get_subnet_id="";

    if [ -z "$_get_subnet_id" -a "$fail_if_not_found" == "true" ]; then
        log_fatal "No subnet with name $subnet_name in VPC ${vpc_id}${vpc_name} found.";
    fi;

    eval "$target_variable_name='$_get_subnet_id'";
}
