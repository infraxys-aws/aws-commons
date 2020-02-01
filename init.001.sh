function append_all_files_in_dir() {
    local function_name="append_all_files_in_dir" directory target_file add_new_line="false";
    import_args "$@";
    check_required_arguments $function_name directory target_file;
    if [ ! -d "$directory" ]; then
        log_debug "Directory $directory doesn't exist so not appending anything to $target_file.";
        return;
    fi;
    cd "$directory" > /dev/null;
    for f in *; do
        log_info "Adding $f";
        cat "$f" >> $target_file;
        if [ "$add_new_line" == "true" ]; then
          echo "" >> $target_file;
        fi;
    done;
    cd - > /dev/null;
}

function set_aws_profile() {
    export function_name="set_aws_profile" profile_name;
    import_args "$@";
    check_required_arguments "$function_name" profile_name;

    log_info "Setting AWS_PROFILE to '$profile_name' and clearing other AWS-variables.";
    export AWS_PROFILE="$profile_name";
    unset AWS_SESSION_ID;
    unset AWS_DEFAULT_REGION;
    unset AWS_SECRET_ACCESS_KEY;
    unset AWS_ACCESS_KEY_ID;

    rm -f ~/.aws/cli/cache/*
    aws sts get-caller-identity --profile $AWS_PROFILE
    if [ -d ~/.aws/cli/cache ]; then
        FILE=$(find ~/.aws/cli/cache/ -name "*.json")
        if [ -n "$FILE" ]; then
            echo "Processing file $FILE";
            export AWS_SECRET_ACCESS_KEY="$(cat "$FILE" | jq -r '.Credentials.SecretAccessKey')";
            export AWS_SESSION_TOKEN="$(cat "$FILE" | jq -r '.Credentials.SessionToken')";
            export AWS_ACCESS_KEY_ID="$(cat "$FILE" | jq -r '.Credentials.AccessKeyId')";
        fi;
  fi;

    #export AWS_SDK_LOAD_CONFIG=1;
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
