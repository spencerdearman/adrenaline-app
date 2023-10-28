import json
import boto3
import os

def lambda_handler(event, context):
    print(event)
    records = event["Records"]
    
    for record in records:
        key = record['s3']['object']['key']
        print("Key:", key)
        
        rest, videoId = os.path.split(key)
        videoId = os.path.splitext(videoId)[0]
        print(f"Video ID:", videoId)
        
        _, email = os.path.split(rest)
        email = email.replace("%40", "@")
        print(f"Email:", email)
        
        client = boto3.client('s3')
        bucket_name = "adrenaline-main-video-streams"
        
        response = client.list_objects_v2(Bucket=bucket_name, Prefix=f"{email}/{videoId}")
        print(response)
        if 'Contents' not in response:
            print("Contents not in dict")
            continue
        
        # Removes extra fields from dict and keeps only Key
        objects = map(lambda x: {'Key': x['Key']}, response['Contents'])

        d = {
                'Objects': list(objects),
                'Quiet': False
        }

        print("List Request:", d)
        print("Objects to be removed:", list(d['Objects']))
        
        response = client.delete_objects(
            Bucket=bucket_name,
            Delete=d
        )
        print(response)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Deletion completed')
    }

