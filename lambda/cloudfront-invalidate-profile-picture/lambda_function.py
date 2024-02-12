import os
import time
import sys
import boto3

client = boto3.client("cloudfront")
DISTRIBUTION_ID = "E3N0YBYC3DU3U6"


def lambda_handler(event, context):
    print(event)
    try:
        key = event["Records"][0]["s3"]["object"]["key"]
        filename = os.path.basename(key)
        print(key)
        print(f"Invalidating {filename}")
    except:
        print("Failed to get key")

    run("/" + filename)


# https://dev.to/vumdao/invalidation-aws-cdn-using-boto3-2k9g
def create_invalidation(path):
    res = client.create_invalidation(
        DistributionId=DISTRIBUTION_ID,
        InvalidationBatch={
            "Paths": {"Quantity": 1, "Items": [path]},
            "CallerReference": str(time.time()).replace(".", ""),
        },
    )
    invalidation_id = res["Invalidation"]["Id"]
    return invalidation_id


def get_invalidation_status(inval_id):
    res = client.get_invalidation(DistributionId=DISTRIBUTION_ID, Id=inval_id)
    return res["Invalidation"]["Status"]


def run(path):
    the_id = create_invalidation(path)
    count = 0
    while True:
        status = get_invalidation_status(the_id)
        if status == "Completed":
            print(f"Completed, id: {the_id}")
            break
        elif count < 10:
            count += 1
            time.sleep(30)
        else:
            print("Timeout, please check CDN")
            sys.exit(1)
