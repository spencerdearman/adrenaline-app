import os
import boto3

COLLECTION_ID = "UserFaces"


def lambda_handler(event, context):
    rek = boto3.client(
        "rekognition",
        region_name="us-east-1",
    )

    print(event)
    records = event["Records"]

    for record in records:
        s3_key = record["s3"]["object"]["key"]
        user_id = os.path.splitext(os.path.basename(s3_key))[0]

        print(f"Profile Pic S3 Key: {s3_key}")
        print(f"User ID: {user_id}")

        print("Getting user faces from collection...")
        face_response = rek.list_faces(CollectionId=COLLECTION_ID, UserId=user_id)
        if "Faces" not in face_response:
            print("ERROR: Failed to get faces associated with user")
            continue

        print(f"Found Faces: {face_response['Faces']}")

        print("Removing user from collection...")
        response = rek.list_users(CollectionId=COLLECTION_ID)
        print(f"Users: {response['Users']}")

        try:
            response = rek.delete_user(CollectionId=COLLECTION_ID, UserId=user_id)
        except Exception as e:
            print(f"ERROR: Failed to delete user, {e}")

        if len(face_response["Faces"]) == 0:
            print("No faces to be deleted")
            continue

        response = rek.delete_faces(
            CollectionId=COLLECTION_ID,
            FaceIds=list(map(lambda x: x["FaceId"], face_response["Faces"])),
        )
        print(f"Deleted Faces: {response}")
