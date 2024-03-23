from rekognition import detect_moderation_labels
import boto3


def lambda_handler(event, context):
    print(event)
    records = event["Records"]
    s3 = boto3.client("s3")
    s3_resource = boto3.resource("s3")
    rek = boto3.client("rekognition", region_name="us-east-1")

    for record in records:
        bucket = record["s3"]["bucket"]["name"]
        s3_key = record["s3"]["object"]["key"].replace("%40", "@")
        print("Bucket:", bucket)
        print("Key:", s3_key)

        try:
            is_safe_content = detect_moderation_labels(rek, bucket, s3_key)

            if is_safe_content:
                print("Content is safe, moving to images directory...")
                new_key = s3_key.replace("-under-review", "")
                s3_resource.Object(bucket, new_key).copy_from(
                    CopySource=f"{bucket}/{s3_key}"
                )

                s3.delete_object(Bucket=bucket, Key=s3_key)
            else:
                print(f"Unsafe content found in {s3_key}")
        except Exception as exc:
            print(f"Failed to detect moderation labels: {repr(exc)}")


# if __name__ == "__main__":
#     lambda_handler(
#         {
#             "Records": [
#                 {
#                     "s3": {
#                         "bucket": {"name": "adrenalinexxxxx153503-main"},
#                         "object": {
#                             "key": "public/images-under-review/lsherwin10@gmail.com/suit.jpg"
#                         },
#                     }
#                 }
#             ]
#         },
#         None,
#     )
