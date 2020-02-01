
# Adding the proxy-command here makes executing functions remote fail
function get_instance_ssh_command_with_proxy_command() {
    local function_name="get_instance_ssh_command" private_ip ssh_connect_username target_variable_name;
    import_args "$@";
    check_required_variables ssh_connect_username private_ip;
    log_fatal "Decprecated. get_instance_ssh_command_with_proxy_command shouldn't be used. Use the ssh-config hostname instead."
    local proxy_command="$(get_bastion_ssh_proxy_command --private_ip $private_ip)";
    local result="ssh -i /tmp/${private_ip}.pem -t $ssh_connect_username@$private_ip -k -o ProxyCommand=\"$proxy_command -W $private_ip:22\" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60 -o LogLevel=ERROR -o PreferredAuthentications=publickey";
    if [ -n "$target_variable_name" ]; then
        eval "$target_variable_name='$result'";
    else
        echo "$result";
    fi;
}