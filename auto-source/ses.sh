function send_mail() {
    local function_name="send_email" from to subject mail_body attachment attachment_filename AWS_REGION="us-east-1";
    import_args "$@";
    check_required_arguments $function_name from to subject mail_body;

    echo "{" > /tmp/message.json;
    echo '"Data":' >> /tmp/message.json;
    echo -n "\"From: $from\n" >> /tmp/message.json;
    echo -n "To: $to\n" >> /tmp/message.json;
    echo -n "Subject: $subject\n" >> /tmp/message.json;
    echo -n "MIME-Version: 1.0\n" >> /tmp/message.json;
    echo -n "Content-type: Multipart/Mixed; " >> /tmp/message.json;
    echo -n " boundary=\\\"NextPart\\\"\n\n--NextPart\nContent-Type: text/plain\n\n" >> /tmp/message.json;
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
