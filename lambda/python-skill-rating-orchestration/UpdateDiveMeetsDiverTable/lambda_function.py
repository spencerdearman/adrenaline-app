# This updates the DiveMeetsDiver DynamoDB table with whatever DiveMeets id list
# is provided as a yyyy-MM-dd in the event dictionary, e.g. { "input_date": "2023-11-30" }
# ID list files are saved here: s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/
# This lambda runs an EC2 instance and logs to this CloudWatch log group: /aws/ec2/update-divemeets-diver-table

import boto3
import json
import time
import os

region = "us-east-1"
ec2_id = os.environ["ec2_id"]
ec2 = boto3.resource("ec2", region_name=region)
ssm_client = boto3.client("ssm")
log_group_name = "/aws/ec2/update-divemeets-diver-table"


def lambda_handler(event, context):
    instance = ec2.Instance(id=ec2_id)
    print("starting instance " + ec2_id)
    instance.start()
    instance.wait_until_running(
        Filters=[
            {
                "Name": "instance-state-name",
                "Values": [
                    "running",
                ],
            },
        ]
    )

    print(f"{event=}")
    assert "input_date" in event
    input_date = event["input_date"]

    script = f"""
#!/bin/bash
echo "Copying starter code..."
cd /home/ec2-user
aws s3 cp --recursive s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/update-dynamodb/ update-divemeets-diver-table/update-dynamodb/
cd update-divemeets-diver-table
echo "Creating virtual environment..."
sudo python3 -m venv venv
sudo chmod -R a+rwx venv
source venv/bin/activate
echo "Installing python dependencies..."
pip install --upgrade pip
pip install requests-futures boto3 bs4 html5lib simplejson
echo "Copying from S3..."
aws s3 cp "s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/{input_date}.csv" ids.csv
cd update-dynamodb 
python_script="from driver import run; run(\\"../ids.csv\\")"
echo "Adding python run script..."
echo "$python_script" > start.py
echo "Running python script..."                                              
python -u start.py
cd ..
echo "Script completed, deactivating virtual environment..."
deactivate
cd ..
echo "Removing update-divemeets-diver-table folder..."
sudo rm -rf update-divemeets-diver-table
echo "Completed."
echo "Stopping EC2 instance..."
aws ec2 stop-instances --instance-ids {ec2_id} 
"""

    response = None
    num_retries = 5
    for i in range(num_retries):
        try:
            # Run shell script
            response = ssm_client.send_command(
                DocumentName="AWS-RunShellScript",
                Parameters={"commands": [script]},
                InstanceIds=[ec2_id],
                CloudWatchOutputConfig={
                    "CloudWatchLogGroupName": log_group_name,
                    "CloudWatchOutputEnabled": True,
                },
            )
            print("Send succeeded")
            break
        except Exception as exc:
            print(exc)
            print("Failed response:", response)
            response = None
            print("send command failed, waiting 5 seconds before retrying...")
            time.sleep(5)

    if response is not None:
        # See the command run on the target instance Ids
        print("Response:", response["Command"]["Parameters"]["commands"])

