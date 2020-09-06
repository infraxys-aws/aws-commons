import boto3
from botocore.exceptions import ClientError
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
import os


class SesMail(object):

    def __init__(self):
        pass

    def mail(self, sender, recipient, subject, body_text, body_html, region='us-east-1', profile_name=None):
        CONFIGURATION_SET = "ConfigSet"
        CHARSET = "UTF-8"
        if profile_name:
            client = boto3.session.Session(profile_name=profile_name).client('ses')
        else:
            client = boto3.client('ses', region_name=region)

        try:
            response = client.send_email(
                Destination={
                    'ToAddresses': [
                        recipient,
                    ],
                },
                Message={
                    'Body': {
                        'Html': {
                            'Charset': CHARSET,
                            'Data': body_html,
                        },
                        'Text': {
                            'Charset': CHARSET,
                            'Data': body_text,
                        },
                    },
                    'Subject': {
                        'Charset': CHARSET,
                        'Data': subject,
                    },
                },
                Source=sender,
                # ConfigurationSetName=CONFIGURATION_SET,
            )
        # Display an error if something goes wrong.
        except ClientError as e:
            print(e.response['Error']['Message'])
        else:
            print("Email sent! Message ID:"),
            print(response['MessageId'])


    def send_raw_mail(self, sender, recipients, subject, body_text, body_html, region='us-east-1', attachments=[]):
        multipart_content_subtype = 'mixed' # 'alternative' if f_args['text'] and f_args['html'] else 'mixed'
        msg = MIMEMultipart(multipart_content_subtype)
        msg['Subject'] = subject
        msg['From'] = sender
        msg['To'] = ', '.join(recipients)

        msg.attach(MIMEText(body_text, 'plain'))
        msg.attach(MIMEText(body_html, 'html'))

        # Add attachments
        for attachment in attachments:
            with open(attachment, 'rb') as f:
                part = MIMEApplication(f.read())
                part.add_header('Content-Disposition', 'attachment', filename=os.path.basename(attachment))
                msg.attach(part)

        client = boto3.client('ses', region_name=region)

        try:
            response = client.send_raw_email(
                Source=sender,
                Destinations=recipients,
                RawMessage={'Data': msg.as_string()})

        # Display an error if something goes wrong.
        except ClientError as e:
            print(e.response['Error']['Message'])
        else:
            print("Email sent! Message ID:"),
            print(response['MessageId'])

        """
        message_dict = {
            'Data':
                'From: ' + sender + '\n'
                                    'To: ' + recipient + '\n'
                                                         'Subject: ' + subject + '\n'
                                                                                'MIME-Version: 1.0\n'
                                                                                'Content-Type: text/html;\n\n' +
                body_html}

        response = client.send_raw_email(
            Destinations=[
                recipient
            ],
            FromArn='',
            RawMessage=message_dict,
            ReturnPathArn='',
            Source='',
            SourceArn='',
        )

        return ses.send_raw_email(
            Source=f_args['sender'],
            Destinations=f_args['recipients'],
            RawMessage={'Data': msg.as_string()}
        )

        try:
            response = client.send_email(
                Destination={
                    'ToAddresses': [
                        recipient,
                    ],
                },
                Message={
                    'Body': {
                        'Html': {
                            'Charset': CHARSET,
                            'Data': body_html,
                        },
                        'Text': {
                            'Charset': CHARSET,
                            'Data': body_text,
                        },
                    },
                    'Subject': {
                        'Charset': CHARSET,
                        'Data': subject,
                    },
                },
                Source=sender,
                # ConfigurationSetName=CONFIGURATION_SET,
            )
        # Display an error if something goes wrong.
        except ClientError as e:
            print(e.response['Error']['Message'])
        else:
            print("Email sent! Message ID:"),
            print(response['MessageId'])
        """