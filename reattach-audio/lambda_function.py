import json
import boto3
from botocore.exceptions import NoCredentialsError
import subprocess
import shlex
import os


def lambda_handler(event, context):
    return {
        "statusCode": 400,
        "body": json.dumps("Service currently disabled"),
    }

    dest_s3_key = event["key"].replace("%40", "@")
    dest_s3_bucket = event["bucket"]
    dest_s3 = "s3://" + dest_s3_bucket + "/" + dest_s3_key

    source_s3_key = dest_s3_key
    source_s3_bucket = "adrenaline-reattach-audio"
    source_s3 = "s3://" + source_s3_bucket + "/" + source_s3_key

    print(f"Source S3 Key: {dest_s3_key}")
    print(f"Source S3 Bucket: {source_s3_bucket}")
    print(f"Source S3: {source_s3}")

    print(f"Dest S3 Key: {dest_s3_key}")
    print(f"Dest S3 Bucket: {dest_s3_bucket}")
    print(f"Dest S3: {dest_s3}")

    s3_client = boto3.client("s3")

    # Getting presigned URL for newly processed video passed into S3 bucket
    # to overlay with original audio
    s3_source_signed_url = s3_client.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": source_s3_bucket, "Key": source_s3_key},
    )
    videoFile = "/tmp/video.mp4"
    saveVideo(videoFile, s3_source_signed_url)

    # Getting presigned URL for original video to pull audio from and overlay
    # with newly processed video
    s3_dest_signed_url = s3_client.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": dest_s3_bucket, "Key": dest_s3_key},
    )
    audioFile = "/tmp/audio.mp4"
    # saveVideo(audioFile, s3_dest_signed_url)

    output_filename = "/tmp/" + os.path.basename(dest_s3_key)

    ffmpeg_cmd = (
        '/opt/bin/ffmpeg -i "'
        + videoFile
        + '" -i "'
        + audioFile
        + '"-c:v copy -map 0:v:0 -map 1:a:0 -c:a aac -b:a 192k "'
        + output_filename
        + '"'
    )

    command1 = shlex.split(ffmpeg_cmd)
    print("Args:", command1)

    result = subprocess.call(command1)
    if result == 0:
        print("Subprocess executed successfully")
    else:
        print("Subprocess failed")

    try:
        s3_client.upload_file(output_filename, dest_s3_bucket, dest_s3_key)
        print("Successfully uploaded back to S3")
    except FileNotFoundError:
        result = {
            "statusCode": 400,
            "body": json.dumps(f"The file {output_filename} was not found"),
        }
        print(result)
        return result
    except NoCredentialsError:
        result = {
            "statusCode": 400,
            "body": json.dumps("Credentials not available"),
        }
        print(result)
        return result

    try:
        os.remove(videoFile)
        os.remove(audioFile)
        os.remove(output_filename)
    except OSError:
        print("File not found, unable to remove")

    return {"statusCode": 200, "body": json.dumps("Processing complete successfully")}
