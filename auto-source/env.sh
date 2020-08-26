export PYTHONPATH="$(pwd)/python:$PYTHONPATH";

function generate_ssh_config_for_vpc() {
    local function_name="generate_ssh_config_for_vpc" vpc_name name_list_json_file="/tmp/servers.json";
    import_args "$@";
    check_required_arguments "$function_name" vpc_name;
    log_info "Generating SSH configuration for VPC $vpc_name into ~/.ssh/generated.d/$vpc_name.";

    local _ssh_config="$("$AWS_COMMONS_MODULE_DIR/utils/generate_vpc_ssh_config.py" "$vpc_name" "$name_list_json_file")";
    if [ $? -eq 0 ]; then
        log_info "SSH config generated.";
        echo "$_ssh_config" > ~/.ssh/generated.d/$vpc_name;
        cat ~/.ssh/generated.d/$vpc_name
    else
        log_error "Unable to generate ssh config for vpc '$vpc_name'.";
    fi;
}

# Make sure that you pass the arguments for the remote function as the last ones in the list
function aws_execute_function_over_ssh() {
    local vpc_id private_ips aws_profile_name override_ssh_user vault_config_variable \
        instance_name function_name vpc_name reqion extra_functions_to_export extra_arguments vault_ssh_key_root \
        pause_in_between callback results_file init_ssh_and_aws="true";

    import_args "$@";
    check_required_arguments "aws_execute_function_over_ssh" aws_profile_name vpc_name region instance_name function_name \
        vault_ssh_key_root vault_config_variable;

    shift 8; # remove the first arguments because there's no need to pass them all

    if [ "$init_ssh_and_aws" == "true" ]; then
        set_aws_profile --profile_name "$aws_profile_name"
        generate_ssh_config_for_vpc --vpc_name "$vpc_name";

        get_ssh_keys_from_vault --vault_config_variable "$vault_config_variable" \
            --vault_ssh_key_root "$vault_ssh_key_root";
    fi;

    local first="true";
    for host in $(cat /tmp/servers.json | jq -cr '.["'$instance_name'"] | .[]'); do
        if [ "$first" == "false" -a -n "$pause_in_between" ]; then
            if [ "$pause_in_between" == "pause" ]; then
                read -p "Press enter to continue with the next instance. ";
            else
                echo
                log_info "Waiting $pause_in_between seconds before continuing.";
                sleep $pause_in_between;
            fi;
        fi;
        hostname="$(echo "$host" | jq -r '.hostname')";
        private_ip="$(echo "$host" | jq -r '.privateIpAddress')";
        log_info "Launching function $function_name on $hostname.";
        execute_function_over_ssh --function_name "$function_name" --hostname "$hostname" --exit_on_error "false" \
            --override_ssh_user "$override_ssh_user" \
            --extra_functions_to_export "$extra_functions_to_export" "$@";

        if [ -n "$results_file" ]; then
            scp -q $hostname:$results_file $results_file;
            if [ -n $callback ]; then
                $callback --exit_code "$LAST_SSH_EXIT_CODE" --results_file "$results_file" --hostname "$hostname" \
                    --private_ip "$private_ip";
            fi;
        elif [ -n "$callback" ]; then
            $callback --exit_code "$LAST_SSH_EXIT_CODE" --hostname "$hostname" --private_ip "$private_ip";
        elif [ $LAST_SSH_EXIT_CODE -ne 0 ]; then
            log_error "Last SSH exit code was '$LAST_SSH_EXIT_CODE'. Aborting.";
            exit $LAST_SSH_EXIT_CODE;
        fi;
        first="false";
    done;
    set -e;
    log_info "All instances processed.";
}
