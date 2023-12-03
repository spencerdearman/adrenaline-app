# This generates a list of DiveMeets ids that fall in high school age range or
# graduation years to update the Adrenaline rankings list. It saves these lists
# as a CSV titled yyyy-MM-dd.csv for the given run date.
# This should execute on a weekly schedule on Wedesndays at 9AM ET (UTC-5).
# If this is being run manually, you must provide a dictionary like
# this: { "start_index": "25000", "end_index": "150000" },
# where the ints can be changed to update the DiveMeets id range that will be parsed.
# ID list files are saved here: s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/
# This lambda runs an EC2 instance and logs to this CloudWatch log group: /aws/ec2/update-divemeets-diver-table

import boto3
import json
import time
import os
from datetime import datetime
from zoneinfo import ZoneInfo

region = "us-east-1"
ec2_id = os.environ["ec2_id"]
ec2 = boto3.resource("ec2", region_name=region)
ssm_client = boto3.client("ssm")
log_group_name = "/aws/ec2/update-divemeets-diver-table"


def lambda_handler(event, context):
    instance = ec2.Instance(id=ec2_id)
    # print("starting instance " + ec2_id)
    # instance.start()
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
python_script="from script import run; run({eventJson}, \\"{log_group_name}\\")"
echo "Copying starter code..."

cd /home/ec2-user

# Clean up any leftover resources that were missed from a previous failure
rm -r update-divemeets-diver-table && {{ echo "Removed old update-divemeets-diver-table folder before continuing..."; }} || {{ echo "No old update-divemeets-diver-table found, continuing..."; }}

# Copy necessary scripts to the filesystem
aws s3 cp s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/script.py update-divemeets-diver-table/script.py && \
aws s3 cp --recursive s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/update-dynamodb/ update-divemeets-diver-table/update-dynamodb/ && \
cd update-divemeets-diver-table || {{ echo "Failed to copy data from S3."; exit 1; }}

# Set up python virtual environment
echo "Creating virtual environment..." && \
sudo python3 -m venv venv && \
sudo chmod -R a+rwx venv && \
source venv/bin/activate && \
pip install --upgrade pip && \
pip install requests-futures boto3 bs4 html5lib simplejson || {{ echo "Failed to set up python virtual environment."; exit 1; }}

# Initiate python script
echo "Adding python run script..." && \
echo "$python_script" > start.py && \
echo "Running script..." && \
python -u start.py && \
echo "Script completed successfully" && \
echo "Copying to S3..." && \
date=$(date -d "-5 hours" +%F) && \
aws s3 cp ids.csv "s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/$date.csv" || {{ echo "Python script failed to execute successfully."; exit 1; }}

# Clean up resources
cd ..
echo "Deactivating virtual environment..."
deactivate && \
cd .. && \
echo "Removing update-divemeets-diver-table folder..." && \
sudo rm -rf update-divemeets-diver-table && \
echo "Completed."
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
            print(repr(exc))
            print("Failed response:", response)
            response = None
            print("send command failed, waiting 5 seconds before retrying...")
            time.sleep(5)

    if response is not None:
        # See the command run on the target instance Ids
        print("Response:", response["Command"]["Parameters"]["commands"])

        return {
            "input_date": datetime.now()
            .astimezone(ZoneInfo("America/New_York"))
            .strftime("%Y-%m-%d")
        }

    return {}
