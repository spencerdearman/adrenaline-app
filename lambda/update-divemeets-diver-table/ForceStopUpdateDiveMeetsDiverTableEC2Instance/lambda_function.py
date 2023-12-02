import os
import boto3
from datetime import datetime

region = "us-east-1"
ec2_id = os.environ["ec2_id"]
ec2 = boto3.resource("ec2", region_name=region)
cloudwatch_client = boto3.client("cloudwatch", region_name=region)
ssm_client = boto3.client("ssm")


def lambda_handler(event, context):
    instance = ec2.Instance(id=ec2_id)
    if instance.state["Name"] == "running":
        print("EC2 instance is still running, forcefully stopping...")
        instance.stop()
        cloudwatch_client.put_metric_data(
            Namespace="UpdateDiveMeetsDiverTable",
            MetricData=[
                {
                    "MetricName": "ForceStopUpdateDiveMeetsDiverTableEC2Instance Invocations",
                    "Timestamp": datetime.now(),
                    "Value": 1.0,
                    "Unit": "Count",
                }
            ],
        )
    else:
        print("EC2 instance is already stopped, no action needed.")

