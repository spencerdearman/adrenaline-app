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

        body = f"""A user has requested to associate with a college. Invoke the below lambda to update this association. If college ID is blank, provide an empty string in the "college_id" field of the input JSON.

{{
   "user_id": "{user_id}",
   "college_id": "{college_id}"
}}

S3 Location: https://s3.console.aws.amazon.com/s3/buckets/adrenalinexxxxx153503-main?region=us-east-1&bucketType=general&prefix=public/college-association-requests/&showversions=false
Lambda Function: https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/approve-college-association-request
"""

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
