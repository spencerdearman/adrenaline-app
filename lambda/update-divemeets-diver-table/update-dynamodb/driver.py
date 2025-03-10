import os
import uuid
from process_ids import process_ids
import boto3
from cloudwatch import init_cloudwatch_logs


# Used for manual runs or EC2 instances to run on a local file
def run(filename, log_group_name=None, isLocal=False):
    region = "us-east-1"
    logs_client = boto3.client("logs", region_name=region)
    log_stream_name = f"python-dynamodb-script-logs-{uuid.uuid4()}"

    if not isLocal:
        init_cloudwatch_logs(logs_client, log_group_name, log_stream_name)

    os.environ["bucket_name"] = "adrenalinexxxxx153503-main"
    with open(filename, "r", encoding="UTF-8") as f:
        csv = f.read().splitlines()
        process_ids(csv, logs_client, log_group_name, log_stream_name, isLocal)


if __name__ == "__main__":
    run("../ids.csv", "/aws/ec2/update-divemeets-diver-table", True)
