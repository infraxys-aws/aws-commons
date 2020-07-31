function send_mail() {
    local from to subject mail_body mail_body_file attachment attachment_filename AWS_REGION aws_region;
    import_args "$@";
    check_required_arguments send_email from to subject;
    check_required_argument send_email mail_body mail_body_file;

    [[ -n "$aws_region" ]] && AWS_REGION="$aws_region";
    [[ -z "$AWS_REGION" ]] && AWS_REGION="us-east-1";

    if [ -z "$mail_body" ]; then
        mail_body="$(cat "$mail_body_file" | tr -d "\n" | tr -d "\r" | sed 's/"/\\"/g')";
    fi;

    echo "{" > /tmp/message.json;
    echo '"Data":' >> /tmp/message.json;
    echo -n "\"From: $from\n" >> /tmp/message.json;
    echo -n "To: $to\n" >> /tmp/message.json;
    echo -n "Subject: $subject\n" >> /tmp/message.json;
    echo -n "MIME-Version: 1.0\n" >> /tmp/message.json;
    echo -n "Content-type: Multipart/Mixed; " >> /tmp/message.json;
    echo -n " boundary=\\\"NextPart\\\"\n\n--NextPart\nContent-Type: text/html\n\n" >> /tmp/message.json;
    echo -n "$mail_body.\n\n--NextPart\n" >> /tmp/message.json;
    echo -n "Content-Type: text/plain;\n" >> /tmp/message.json;
    if [ "$attachment" != "" ]; then
        local attachment_in_base64="$(cat $attachment | base64 -w 0 -)";
        echo -n "Content-Disposition: attachment; filename=\\\"$attachment_filename\\\"\n" >> /tmp/message.json;
        echo -n "Content-Transfer-Encoding: base64\n\n" >> /tmp/message.json;
        echo -n "$attachment_in_base64\n\n" >> /tmp/message.json;
    fi;
    echo -n "--NextPart--\"" >> /tmp/message.json;
    echo "" >> /tmp/message.json;
    echo "}" >> /tmp/message.json;
    unset HOME # Necessary for aws cli
    log_info "Sending mail to $to.";

    aws ses send-raw-email --region $AWS_REGION --raw-message file:///tmp/message.json;
    log_info "Mail sent.";
}

