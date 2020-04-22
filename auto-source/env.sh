export AWS_COMMONS_MODULE_DIR="$(pwd)";

function generate_ssh_config_for_vpc() {
  local function_name="generate_ssh_config_for_vpc" vpc_name name_list_json_file="/tmp/servers.json";
  import_args "$@";
  check_required_arguments "$function_name" vpc_name;
  log_info "Generating SSH configuration for VPC $vpc_name into ~/.ssh/generated.d/$vpc_name.";

  local _ssh_config="$("$AWS_COMMONS_MODULE_DIR/utils/generate_vpc_ssh_config.py" "$vpc_name" "$name_list_json_file")";
  if [ $? -eq 0 ]; then
    echo "$_ssh_config" > ~/.ssh/generated.d/$vpc_name;
  else
    log_error "Unable to generate ssh config for vpc '$vpc_name'.";
  fi;
}