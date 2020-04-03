export AWS_COMMONS_MODULE_DIR="$(pwd)";

function generate_ssh_config_for_vpc() {
  local function_name="generate_ssh_config_for_vpc" vpc_name name_list_json_file get_ssh_keys="false";
  import_args "$@";
  check_required_arguments "$function_name" vpc_name;
  log_info "Generating SSH configuration for VPC $vpc_name into ~/.ssh/generated.d/$vpc_name.";
  "$AWS_COMMONS_MODULE_DIR/utils/generate_vpc_ssh_config.py" "$vpc_name" "$name_list_json_file" > ~/.ssh/generated.d/$vpc_name;
}