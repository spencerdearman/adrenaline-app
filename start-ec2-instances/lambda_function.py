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

    eventJson = json.dumps(event).replace('"', '\\"')
    print(f"{event=}, JSON: {eventJson}")
    script = f"""
#!/bin/bash
python_script="from script import run; run({eventJson})"
echo "Copying starter code..."
cd /home/ec2-user
aws s3 cp s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/script.py update-divemeets-diver-table/script.py
cd update-divemeets-diver-table
echo "Creating virtual environment..."
sudo python3 -m venv venv
sudo chmod -R a+rwx venv
source venv/bin/activate
pip install --upgrade pip
pip install requests-futures boto3
echo "Adding python run script..."
echo "$python_script" > start.py
echo "Running script..."                                              
python -u start.py
echo "Script completed, deactivating virtual environment..."
deactivate
echo "Copying to S3..."
date=$(date -d "-5 hours" +%F)
aws s3 cp ids.csv "s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/$date.csv"
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
        except:
            print("Failed response:", response)
            response = None
            print("send command failed, waiting 5 seconds before retrying...")
            time.sleep(5)

    if response is not None:
        # See the command run on the target instance Ids
        print("Response:", response["Command"]["Parameters"]["commands"])
