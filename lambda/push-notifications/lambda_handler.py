import os
import json
import boto3

print('Loading function')

def lambda_handler(event, context):
    for record in event['Records']:
        # print(record['eventID'])
        # print(record['eventName'])
        # print("DynamoDB Record: " + json.dumps(record['dynamodb'], indent=2))
            
        if record["eventName"] != 'INSERT':
            print("Not an insert event")
            continue
        if record["dynamodb"]["NewImage"]["isSender"]["BOOL"]:
            continue
        
        # print(record)
        recordDynamoDBNewImage = record["dynamodb"]["NewImage"]
        messageID = recordDynamoDBNewImage["messageID"]["S"]
        newUserID = recordDynamoDBNewImage["newuserID"]["S"]
        
        client = boto3.client("dynamodb", region_name="us-east-1")
        
        response = client.query(
        ExpressionAttributeValues={
            ':v1': {
                'S': messageID,
            },
        },
        KeyConditionExpression='messageID = :v1',
        TableName=os.environ["MessageNewUserTable"],
        IndexName='byMessage'
        )
        
        messageNewUser = list(filter(lambda x: x["isSender"]["BOOL"], response["Items"]))[0]
        
        senderNewUserID = messageNewUser["newuserID"]["S"]

        senderNewUser = client.get_item(
            ConsistentRead=True,
            TableName= os.environ['NewUserTable'],
            Key={
                'id': {
                    'S': senderNewUserID,
                }
            }
        )
        # print(senderNewUser)
        senderFirst = senderNewUser["Item"]["firstName"]["S"]
        senderLast = senderNewUser["Item"]["lastName"]["S"]
        
        message = client.get_item(
            ConsistentRead=True,
            TableName= os.environ['MessageTable'],
            Key={
                'id': {
                    'S': messageID,
                }
            }
        )
        
        newUser = client.get_item(
            ConsistentRead=True,
            TableName= os.environ['NewUserTable'],
            Key={
                'id': {
                    'S': newUserID,
                }
            }
        )
        
        # print("Message:", message)
        # print("NewUser: ", newUser)
        
        tokens = map(lambda x: x["S"], newUser["Item"]["tokens"]["L"])
        addresses = {k: {'ChannelType': 'APNS_SANDBOX'} for k in list(tokens)}
        messageBody = message["Item"]["body"]["S"]
        
        pin_client = boto3.client('pinpoint', region_name="us-east-1")
        
        # SWITCH FROM SANDBOX TO REGULAR APNS
        response = pin_client.send_messages(
            ApplicationId= os.environ["AppID"],
            MessageRequest={
                'Addresses': addresses,
                'MessageConfiguration': {
                    'APNSMessage': {
                        'Action': 'OPEN_APP',
                        'Body': messageBody,
                        'Title': senderFirst + " " + senderLast,
                    }
                }
            }
        )

        print("Pinpoint response:", response)
        
    return 'Successfully processed {} records.'.format(len(event['Records']))

