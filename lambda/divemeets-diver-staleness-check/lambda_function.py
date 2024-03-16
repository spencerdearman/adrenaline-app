import datetime as dt
from datetime import timezone, datetime
import boto3


def lambda_handler(event, context):
    dynamodb_client = boto3.client("dynamodb", region_name="us-east-1")
    cloudwatch_client = boto3.client("cloudwatch", region_name="us-east-1")
    yesterday = datetime.now(tz=timezone.utc) - dt.timedelta(days=1)
    yesterday_unix_timestamp = int(yesterday.timestamp() * 1000)

    response = dynamodb_client.scan(
        TableName="DiveMeetsDiver-mwfmh6eukfhdhngcz756xxhxsa-main",
        Select="COUNT",
        ExpressionAttributeNames={"#L": "_lastChangedAt"},
        ExpressionAttributeValues={
            ":yesterdayUnixTimestamp": {"N": str(yesterday_unix_timestamp)}
        },
        FilterExpression="#L <= :yesterdayUnixTimestamp",
    )

    response_count = 0
    failure_count = 0
    if "Count" in response:
        response_count = response["Count"]
        failure_count = 0
    else:
        failure_count = 1

    # Only post stale entries metric if there isn't a failure
    if failure_count == 0:
        cloudwatch_client.put_metric_data(
            Namespace="UpdateDiveMeetsDiverTable",
            MetricData=[
                {
                    "MetricName": "DiveMeetsDiverTableStaleEntries",
                    "Timestamp": datetime.now(tz=timezone.utc),
                    "Value": response_count,
                    "Unit": "Count",
                }
            ],
        )

    # Always post a failure metric, whether it is 0 or 1
    cloudwatch_client.put_metric_data(
        Namespace="UpdateDiveMeetsDiverTable",
        MetricData=[
            {
                "MetricName": "DiveMeetsDiverTableStalenessCheckFailures",
                "Timestamp": datetime.now(tz=timezone.utc),
                "Value": failure_count,
                "Unit": "Count",
            }
        ],
    )


if __name__ == "__main__":
    lambda_handler(None, None)
