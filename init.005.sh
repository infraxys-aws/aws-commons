
function set_aws_profile() {
    export profile_name;
    import_args "$@";
    check_required_arguments set_aws_profile profile_name;

    log_info "Setting AWS_PROFILE to '$profile_name' and clearing other AWS-variables.";
    export AWS_PROFILE="$profile_name";
    unset AWS_SESSION_ID;
    unset AWS_DEFAULT_REGION;
    unset AWS_SECRET_ACCESS_KEY;
    unset AWS_ACCESS_KEY_ID;

    rm -f ~/.aws/cli/cache/* # this is used when assuming a role
    local identity="";
    while [ -z "$identity" ]; do
      local identity=$(aws sts get-caller-identity); # script exits if "local" is not used
    done;

    local username=$(echo -- "$identity" | sed -n 's!.*"arn:aws:iam::.*:user/\(.*\)".*!\1!p')
    local tokens="";
    if [ -n "$username" ]; then # logging in without assuming a role
      mfa=$(aws iam list-mfa-devices --user-name "$username")
      device=$(echo -- "$mfa" | sed -n 's!.*"SerialNumber": "\(.*\)".*!\1!p')
      if [ -n "$device" ]; then
        read -p "Enter MFA code for $device: " mfa_code;
        tokens=$(aws sts get-session-token --serial-number "$device" --token-code $mfa_code)
      fi;
    else
      if [ -d ~/.aws/cli/cache ]; then
        local FILE=$(find ~/.aws/cli/cache/ -name "*.json")
        if [ -n "$FILE" ]; then
          tokens=$(cat "$FILE");
        fi;
      fi;
    fi;
    if [ -n "$tokens" ]; then
      export AWS_SECRET_ACCESS_KEY="$(echo "$tokens" | jq -r '.Credentials.SecretAccessKey')";
      export AWS_SESSION_TOKEN="$(echo "$tokens" | jq -r '.Credentials.SessionToken')";
      export AWS_ACCESS_KEY_ID="$(echo "$tokens" | jq -r '.Credentials.AccessKeyId')";
      expiration="$(echo "$tokens" | jq -r '.Credentials.Expiration')";
      echo "Code is valid until $expiration";
    fi;
}

mkdir ~/.aws;
append_all_files_in_dir --directory "$INFRAXYS_ROOT/variables/AWS-CREDENTIALS" --target_file ~/.aws/credentials --add_new_line "true";
append_all_files_in_dir --directory "$INFRAXYS_ROOT/variables/AWS-CONFIG" --target_file ~/.aws/config --add_new_line "true";
chmod -R 600 ~/.aws;

if [ -n "$auto_connect_aws_profile_name" ]; then
  set_aws_profile --profile_name "$auto_connect_aws_profile_name";
elif [ -n "$aws_core_credentials_default_profile_or_role" ]; then
  if [ "$no_aws_auto_login" == "1" -o "$no_aws_auto_login" == "true" ]; then
    log_info "Variable no_aws_auto_login is $no_aws_auto_login, so not authenticating with aws_core_credentials_default_profile_or_role.";
  elif [ "$aws_core_credentials_default_profile_or_role" == "IAM_ROLE" ]; then
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-"$aws_region"}";
    log_info "Using the instance profile role with AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION";
  else
    set_aws_profile --profile_name "$aws_core_credentials_default_profile_or_role";
  fi;
else
  log_info "Not setting AWS environment automatically because variable 'aws_core_credentials_default_profile_or_role' is not set."
fi;
