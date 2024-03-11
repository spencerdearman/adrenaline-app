import json
import os
import boto3

client = boto3.client("ses", region_name="us-east-1")
s3client = boto3.client("s3")


def lambda_handler(event, context):
    result = []
    for record in event["Records"]:
        filename = record["s3"]["object"]["key"]
        user_id, college_id = os.path.splitext(os.path.basename(filename))[0].split("_")

        body = f'User "{user_id}" has requested to associate with the college "{college_id}". Match this college ID with the coach associated with this user to update their association.'

        # Generate email response
        response = client.send_email(
            Destination={
                "ToAddresses": ["logansherwin@adren.tech", "spencerdearman@adren.tech"]
            },
            Message={
                "Body": {
                    "Text": {
                        "Charset": "UTF-8",
                        "Data": body,
                    }
                },
                "Subject": {
                    "Charset": "UTF-8",
                    "Data": "College Association Request",
                },
            },
            Source="logansherwin@adren.tech",
        )

        result.append(
            {
                "statusCode": 200,
                "body": json.dumps(
                    "Email Sent Successfully. MessageId is: " + response["MessageId"]
                ),
            }
        )

    return result
