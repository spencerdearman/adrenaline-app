import json
import os
from urllib.parse import urlparse
import uuid
import boto3
from lib.check_vertical_video import checkVerticalVideo

"""
When you run an S3 Batch Operations job, your job  
invokes this Lambda function. Specifically, the Lambda function is 
invoked on each video object listed in the manifest that you specify 
for the S3 Batch Operations job in Step 5.  

Input parameter "event": The S3 Batch Operations event as a request
                         for the Lambda function.

Input parameter "context": Context about the event.

Output: A result structure that Amazon S3 uses to interpret the result 
        of the operation. It is a job response returned back to S3 Batch Operations.
"""


def handler(event, context):
    print(event)
    records = event["Records"]

    for record in records:
        # Establishes landscape resolution pairs
        resolution_widths = [640, 960, 1280, 1920]
        resolution_heights = [360, 540, 720, 1080]

        source_s3_key = record["s3"]["object"]["key"].replace("%40", "@")
        source_s3_bucket = record["s3"]["bucket"]["name"]
        source_s3 = "s3://" + source_s3_bucket + "/" + source_s3_key

        print(f"Source S3 Key: {source_s3_key}")
        print(f"Source S3 Bucket: {source_s3_bucket}")
        print(f"Source S3: {source_s3}")

        # Runs processing on video and returns True if the video is meant to be
        # using vertical resolutions, False otherwise
        is_vertical_video = checkVerticalVideo(source_s3_bucket, source_s3_key)
        if is_vertical_video is None:
            print("Video processing failed, aborting....")
            return

        print(f"Vertical Video? {is_vertical_video}")

        # Flip resolutions to vertical video if needed
        if is_vertical_video:
            resolution_widths, resolution_heights = (
                resolution_heights,
                resolution_widths,
            )

        result_list = []
        result_code = "Succeeded"
        result_string = "The input video object was converted successfully."

        # The type of output group determines which media players can play
        # the files transcoded by MediaConvert.
        # For more information, see Creating outputs with AWS Elemental MediaConvert.
        output_group_type_dict = {
            "HLS_GROUP_SETTINGS": "HlsGroupSettings",
            "FILE_GROUP_SETTINGS": "FileGroupSettings",
            "CMAF_GROUP_SETTINGS": "CmafGroupSettings",
            "DASH_ISO_GROUP_SETTINGS": "DashIsoGroupSettings",
            "MS_SMOOTH_GROUP_SETTINGS": "MsSmoothGroupSettings",
        }

        try:
            job_name = "output"
            with open("job.json") as file:
                job_settings = json.load(file)

            job_settings["Inputs"][0]["FileInput"] = source_s3

            output_path = "/".join(source_s3_key.split("/")[-2:])

            source_s3_key_basename = os.path.splitext(output_path)[0]
            job_basename = os.path.splitext(os.path.basename(job_name))[0]

            print(f"Source S3 Key Basename: {source_s3_key_basename}")
            print(f"Job Basename: {job_basename}")

            # The path of each output video is constructed based on the values of
            # the attributes in each object of OutputGroups in the job.json file.
            destination_s3 = "s3://{0}/{1}/{2}".format(
                os.environ["DestinationBucket"],
                source_s3_key_basename,
                job_basename,
            )

            print(f"Destination S3: {destination_s3}")

            for output_group in job_settings["OutputGroups"]:
                output_group_type = output_group["OutputGroupSettings"]["Type"]
                if output_group_type not in output_group_type_dict.keys():
                    raise ValueError(
                        "Exception: Unknown Output Group Type {}.".format(
                            output_group_type
                        )
                    )

                output_group_type = output_group_type_dict[output_group_type]
                output_group["OutputGroupSettings"][output_group_type][
                    "Destination"
                ] = "{0}{1}".format(
                    destination_s3,
                    urlparse(
                        output_group["OutputGroupSettings"][output_group_type][
                            "Destination"
                        ]
                    ).path,
                )

                print(
                    "Output Path: {0}{1}".format(
                        destination_s3,
                        urlparse(
                            output_group["OutputGroupSettings"][output_group_type][
                                "Destination"
                            ]
                        ).path,
                    )
                )

                if "Outputs" not in output_group:
                    continue

                for i, output in enumerate(output_group["Outputs"]):
                    if "VideoDescription" not in output:
                        continue

                    idx = i if len(output_group["Outputs"]) > 1 else -1
                    if idx < len(resolution_widths):
                        output["VideoDescription"]["Width"] = resolution_widths[idx]
                    if idx < len(resolution_heights):
                        output["VideoDescription"]["Height"] = resolution_heights[idx]

            job_metadata_dict = {
                "assetID": str(uuid.uuid4()),
                "application": os.environ["Application"],
                "input": source_s3,
                "settings": job_name,
            }

            region = os.environ["AWS_DEFAULT_REGION"]
            endpoints = boto3.client(
                "mediaconvert", region_name=region
            ).describe_endpoints()
            client = boto3.client(
                "mediaconvert",
                region_name=region,
                endpoint_url=endpoints["Endpoints"][0]["Url"],
                verify=False,
            )

            try:
                client.create_job(
                    Role=os.environ["MediaConvertRole"],
                    UserMetadata=job_metadata_dict,
                    Settings=job_settings,
                )
            # You can customize error handling based on different error codes that
            # MediaConvert can return.
            # For more information, see MediaConvert error codes.
            # When the result_code is TemporaryFailure, S3 Batch Operations retries
            # the task before the job is completed. If this is the final retry,
            # the error message is included in the final report.
            except Exception as error:
                result_code = "TemporaryFailure"
                raise

        except Exception as error:
            if result_code != "TemporaryFailure":
                result_code = "PermanentFailure"
            result_string = str(error)

        finally:
            result_list.append(
                {
                    "resultCode": result_code,
                    "resultString": result_string,
                }
            )

    return {
        "treatMissingKeyAs": "PermanentFailure",
        "results": result_list,
    }
