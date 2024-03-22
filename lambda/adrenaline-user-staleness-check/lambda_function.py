import datetime as dt
from datetime import timezone, datetime
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
new_user_table = dynamodb.Table("NewUser-mwfmh6eukfhdhngcz756xxhxsa-main")
NEW_ATHLETE_TABLE = "NewAthlete-mwfmh6eukfhdhngcz756xxhxsa-main"


def lambda_handler(event, context):
    cloudwatch_client = boto3.client("cloudwatch", region_name="us-east-1")
    failure_count = 0
    response_count = 0
    try:
        yesterday = datetime.now(tz=timezone.utc) - dt.timedelta(days=1)
        yesterday_unix_timestamp = int(yesterday.timestamp() * 1000)

        scan_response = new_user_table.scan(
            FilterExpression=Attr("diveMeetsID").exists()
            & Attr("accountType").eq("Athlete")
        )
        data = scan_response["Items"]

        while "LastEvaluatedKey" in scan_response:
            scan_response = new_user_table.scan(
                ExclusiveStartKey=scan_response["LastEvaluatedKey"]
            )
            data.extend(scan_response["Items"])

        new_athlete_ids = [x["newUserAthleteId"] for x in data]

        batch_get_response = dynamodb.batch_get_item(
            RequestItems={
                NEW_ATHLETE_TABLE: {
                    "Keys": [{"id": x} for x in new_athlete_ids],
                    "ConsistentRead": True,
                }
            }
        )

        stale_entries = [
            x
            for x in batch_get_response["Responses"][NEW_ATHLETE_TABLE]
            if x["_lastChangedAt"] <= yesterday_unix_timestamp
        ]
        print(f"Stale Entries: {stale_entries}")

        response_count = len(stale_entries)
        print(f"Count: {response_count}")
    except Exception as exc:
        print(f"Failed to check Adrenaline user staleness: {repr(exc)}")
        failure_count = 1
    finally:
        # Only post stale entries metric if there isn't a failure
        if failure_count == 0:
            print("Logging staleness count metric...")
            cloudwatch_client.put_metric_data(
                Namespace="UpdateDiveMeetsDiverTable",
                MetricData=[
                    {
                        "MetricName": "NewAthleteTableStaleEntries",
                        "Timestamp": datetime.now(tz=timezone.utc),
                        "Value": response_count,
                        "Unit": "Count",
                    }
                ],
            )

        # Always post a failure metric, whether it is 0 or 1
        print("Logging failure metric...")
        cloudwatch_client.put_metric_data(
            Namespace="UpdateDiveMeetsDiverTable",
            MetricData=[
                {
                    "MetricName": "NewAthleteTableStalenessCheckFailures",
                    "Timestamp": datetime.now(tz=timezone.utc),
                    "Value": failure_count,
                    "Unit": "Count",
                }
            ],
        )


if __name__ == "__main__":
    lambda_handler(None, None)
