import boto3
import time
import os


def checkContentModeration(client, bucket, key):
    response = client.start_content_moderation(
        Video={"S3Object": {"Bucket": bucket, "Name": key}},
        MinConfidence=50,
        NotificationChannel={
            "SNSTopicArn": "arn:aws:sns:us-east-1:861465534182:video-moderation-topic",
            "RoleArn": os.environ["MediaConvertRole"],
        },
        JobTag="ContentModeration",
    )

    job_id = response["JobId"]
    print(f"Started content moderation analysis. JobId: {job_id}")
    response = wait_for_job_completion(client, job_id)
    format_response(response)

    return has_no_inappropriate_content(response)


def wait_for_job_completion(client, job_id):
    # Loops 20 times for a maximum of 60s of wait time per job
    for _ in range(20):
        response = client.get_content_moderation(JobId=job_id)
        job_status = response["JobStatus"]

        if job_status == "SUCCEEDED":
            print("Job was successful")
            break
        elif job_status == "FAILED":
            print("Job failed")
            break
        elif job_status in ["IN_PROGRESS", "PARTIAL_SUCCESS"]:
            print("Job is still in progress, waiting...")
            time.sleep(3)
        else:
            print("Job status:", job_status)
            break

    return response


def format_response(response):
    print("Metadata:", response["VideoMetadata"])

    if len(response["ModerationLabels"]) > 0:
        for detection in response["ModerationLabels"]:
            print(detection["ModerationLabel"])
            print()
    else:
        print("No content was flagged in this video")


# Blocklist created by including relevant top-level or second-level category
# words, which should be captured by the label and parentName
def has_no_inappropriate_content(response):
    # https://docs.aws.amazon.com/rekognition/latest/dg/moderation.html#moderation-api
    blocklist = {
        "Sexual Activity",
        "Adult Toys",
        "Sexual Situations",
        "Violence",
        "Visually Disturbing",
        "Drugs",
        "Tobacco",
        "Alcohol",
        "Gambling",
        "Hate Symbols",
    }

    for detection in response["ModerationLabels"]:
        label = str(detection["ModerationLabel"]["Name"])
        parentName = str(detection["ModerationLabel"]["ParentName"])
        if label in blocklist or parentName in blocklist:
            return False

    return True
