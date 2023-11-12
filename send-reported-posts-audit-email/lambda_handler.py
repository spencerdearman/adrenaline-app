import json
import boto3
import os
import datetime

client = boto3.client('ses', region_name='us-east-1')
s3client = boto3.client('s3')

# Returns dictionary with date as a key containing the date of the audit, and
# result as a key containing a list of strings with the filenames of all the query results
def get_reports_objects(date):
    response = s3client.list_objects_v2(
        Bucket=os.environ["bucket"],
        Prefix=f"public/reported-posts/{date}"
    )
    
    if "Contents" in response:
        result = response["Contents"]
    else:
        result = []
    
    return {
        "date": date,
        "result": list(map(lambda x: x["Key"], result))
    }

def lambda_handler(event, context):
    # Get previous day's date for audit
    date = datetime.datetime.now() - datetime.timedelta(days=1)
    date = date.strftime("%Y-%m-%d")
    
    reports = get_reports_objects(date)
    print("Reports:", reports)
    
    if reports["result"] == []:
        return {
            'statusCode': 200,
            'body': json.dumps("No post reports found, no email sent.")
        }
    
    # Removes prefix path, file extension, and replaces commas with pipe 
    # surrounded by spaces
    rows = list(
                map(
                    lambda x: os.path.splitext(os.path.basename(x))[0]
                                     .replace(",", " | "), 
                    reports["result"]
                )
            )
    
    # Create header and line to form table shape for improved readability
    header = 'ReportingUser' + ' ' * 23 + ' | ReportedUser' + ' ' * 24 + ' | ReportedPost\n'
    line = ''.join(["-" if s != "|" else "+" for s in [*rows[0]]]) + "\n"
    body = header + line + '\n'.join(rows)
    print("Message body:")
    print(body)
    
    # Generate email response
    response = client.send_email(
    Destination={
        'ToAddresses': ['logansherwin@adren.tech']
    },
    Message={
        'Body': {
            'Text': {
                'Charset': 'UTF-8',
                'Data': body,
            }
        },
        'Subject': {
            'Charset': 'UTF-8',
            'Data': f'Reported Posts Audit - {reports["date"]}',
        },
    },
    Source='logansherwin@adren.tech'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps("Email Sent Successfully. MessageId is: " + response['MessageId'])
    }