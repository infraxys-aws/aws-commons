export AWS_COMMONS_MODULE_DIR="$(pwd)";

log_info "Setting the GitHub environment.";

[ -n "$github_user_name" ] && log_info "Setting github_user_name to $github_user_name" && git config --global user.name "$github_user_name";
[ -n "$github_user_email" ] && log_info "Setting github_user_email to $github_user_email" && git config --global user.email "$github_user_email";
git config --global push.default simple

if [ -n "$git_token_variable" ]; then
  log_info "Setting GitHub token to the value of variable '$git_token_variable'.";
  export github_token="$(cat /tmp/infraxys/variables/GITHUB-TOKEN/$git_token_variable)";
fi;