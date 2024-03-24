import os
from datetime import datetime
import boto3
import botocore

COLLECTION_ID = "UserFaces"


def lambda_handler(event, context):
    s3 = boto3.client(
        "s3",
    )
    rek = boto3.client(
        "rekognition",
        region_name="us-east-1",
    )
    textract = boto3.client("textract")

    print(event)
    records = event["Records"]

    for record in records:
        bucket = record["s3"]["bucket"]["name"]
        profilepic_s3_key = record["s3"]["object"]["key"]
        filename = os.path.splitext(os.path.basename(profilepic_s3_key))[0]
        user_id = filename.split("_")[0]
        id_s3_key = f"public/id-cards/{filename}.jpg"

        print(f"S3 Bucket: {bucket}")
        print(f"Profile Pic S3 Key: {profilepic_s3_key}")
        print(f"ID Card S3 Key: {id_s3_key}")
        has_id_image = file_exists(bucket, id_s3_key)
        has_profilepic_image = file_exists(bucket, profilepic_s3_key)
        if not has_id_image and not has_profilepic_image:
            print("No pictures exist to compare")
            continue

        if not has_id_image:
            print("Handling existing user...")
            response = handle_existing_user(
                rek,
                bucket,
                profilepic_s3_key,
                user_id,
            )
        else:
            print("Handling new user...")
            response = handle_new_user(
                s3,
                rek,
                textract,
                bucket,
                profilepic_s3_key,
                user_id,
                bucket,
                id_s3_key,
            )

        if response:
            print("Successfully verified user's identity, copying to parent folder")
            move_to_main_folder(s3, bucket, profilepic_s3_key)
        else:
            print("Failed to verify user's identity")


# https://medium.com/plusteam/move-and-rename-objects-within-an-s3-bucket-using-boto-3-58b164790b78
def move_to_main_folder(s3, bucket, key):
    comps = key.split("/")
    comps[-2] = "profile-pictures"
    new_key = "/".join(comps)
    print(f"Moving from {key} to {new_key}")

    s3_resource = boto3.resource("s3")
    s3_resource.Object(bucket, new_key).copy_from(CopySource=f"{bucket}/{key}")

    s3.delete_object(Bucket=bucket, Key=key)


def handle_existing_user(rek, profilepic_s3_bucket, profilepic_s3_key, user_id):
    response = rek.search_users_by_image(
        CollectionId=COLLECTION_ID,
        Image={"S3Object": {"Bucket": profilepic_s3_bucket, "Name": profilepic_s3_key}},
        UserMatchThreshold=80,
        MaxUsers=1,
        QualityFilter="AUTO",
    )
    if "UserMatches" not in response:
        print("ERROR: Response did not have UserMatches key")
        return False
    print(f"UserMatches: {response['UserMatches']}")

    try:
        if user_id not in set(
            map(lambda x: x["User"]["UserId"], response["UserMatches"])
        ):
            print(f"ERROR: User {user_id} not found with matching face")
            return False
    except KeyError as e:
        print(f"{e}")
        return False

    response = add_faces_to_user(
        rek, user_id, [(profilepic_s3_bucket, profilepic_s3_key)]
    )
    if response is None:
        print("Failed to add faces to existing user")
        return False
    print(f"Added Faces to User: {response}")

    return True


def handle_new_user(
    s3,
    rek,
    textract,
    profilepic_s3_bucket,
    profilepic_s3_key,
    user_id,
    id_s3_bucket,
    id_s3_key,
):
    first_name, last_name, dob = None, None, None
    try:
        user_fields = os.path.splitext(os.path.basename(id_s3_key))[0].split("_")
        _, first_name, last_name, dob = user_fields
        first_name = first_name.lower()
        last_name = last_name.lower()
    except Exception:
        print("Failed to get user fields from filename")
        return False

    id_response = textract.analyze_id(
        DocumentPages=[{"S3Object": {"Bucket": id_s3_bucket, "Name": id_s3_key}}]
    )

    if not verify_id_fields(id_response, first_name, last_name, dob):
        print("Unable to verify ID fields")
        return False
    print("Verified ID fields against user inputs")

    face_matches = compare_faces(
        rek, profilepic_s3_bucket, profilepic_s3_key, id_s3_bucket, id_s3_key
    )

    if len(face_matches) == 0:
        print("ERROR: Failed to find any matching faces.")
        return False

    print(f"FaceMatches: {face_matches}")

    if not check_collection_exists(rek):
        print("ERROR: Failed to get collection")
        return False

    response = rek.list_users(CollectionId=COLLECTION_ID, MaxResults=1)

    if "Users" not in response:
        print("ERROR: Failed to get users")
        return False
    print(f"Users: {response['Users']}")

    # Check that user ID doesn't exist
    if user_id in set(map(lambda x: x["UserId"], response["Users"])):
        print("ERROR: User already exists")
        return False

    # Check that profile picture face doesn't already exist
    response = check_for_seen_face(rek, profilepic_s3_bucket, profilepic_s3_key)
    if len(response) > 0:
        print("ERROR: Face already exists in the collection")
        return False
    print("Did not recognize face")

    # Create a new user with user ID
    response = rek.create_user(CollectionId=COLLECTION_ID, UserId=user_id)

    # Add faces to new user
    response = add_faces_to_user(
        rek,
        user_id,
        [(profilepic_s3_bucket, profilepic_s3_key), (id_s3_bucket, id_s3_key)],
    )
    if response is None:
        print("Failed to add faces to new user")
        return False
    print(f"Added Faces to User: {response}")

    # Remove ID card from S3
    response = s3.delete_object(Bucket=id_s3_bucket, Key=id_s3_key)

    return True


def get_iso_date(date):
    date_formats = [
        "%m/%d/%Y",
        "%m-%d-%Y",
        "%m/%d/%y",
        "%m-%d-%y",
        "%Y-%m-%d",
        "%Y/%m/%d",
    ]
    for date_format in date_formats:
        try:
            return datetime.strptime(date, date_format).strftime("%Y-%m-%d")
        except ValueError:
            continue

    return None


def verify_id_fields(id_response, first_name, last_name, dob):
    try:
        for doc in id_response["IdentityDocuments"][0]["IdentityDocumentFields"]:
            doc_type = doc["Type"]
            value = doc["ValueDetection"]

            match doc_type["Text"]:
                case "FIRST_NAME":
                    print("First Name:", value["Text"])
                    if value["Text"].lower() != first_name:
                        print("First name on ID does not match first name from user")
                        return False
                case "LAST_NAME":
                    print("Last Name:", value["Text"])
                    if value["Text"].lower() != last_name:
                        print("Last name on ID does not match last name from user")
                        return False
                case "DATE_OF_BIRTH":
                    date = value["Text"]
                    iso_date = get_iso_date(date)
                    if iso_date is None:
                        print("Failed to parse date of birth into ISO format")
                        return False
                    print("Date of Birth:", iso_date)
                    if iso_date != dob:
                        print(
                            "Date of Birth on ID does not match date of birth from user"
                        )
                        return False
                case _:
                    continue

    except KeyError:
        print("Unable to access ID response")
        return False

    return True


def add_faces_to_user(rek, user_id, bucket_key_pairs):
    # Check that user exists
    response = rek.list_users(CollectionId=COLLECTION_ID)
    if "Users" not in response:
        print("ERROR: Failed to list users")
        return None

    if user_id not in set(map(lambda x: x["UserId"], response["Users"])):
        print("ERROR: User not found in Collection")
        return None

    # Add the new faces to the Collection
    face_ids = []
    for bucket, key in bucket_key_pairs:
        face_ids += add_faces_to_collection(rek, bucket, key)

    # Associate new faces with the newly created user
    return rek.associate_faces(
        CollectionId=COLLECTION_ID,
        UserId=user_id,
        FaceIds=face_ids,
        UserMatchThreshold=80,
    )


# Returns a list of FaceIds that were successfully added from the given Image
def add_faces_to_collection(rek, bucket, key):
    response = rek.index_faces(
        CollectionId=COLLECTION_ID,
        DetectionAttributes=["FACE_OCCLUDED"],
        Image={"S3Object": {"Bucket": bucket, "Name": key}},
        MaxFaces=1,
        QualityFilter="AUTO",
    )
    if "FaceRecords" not in response:
        print("ERROR: Response did not have FaceRecords key")
        return False

    try:
        return list(map(lambda x: x["Face"]["FaceId"], response["FaceRecords"]))
    except KeyError as e:
        print(f"{e}")
        return []


# https://stackoverflow.com/a/33843019
def file_exists(bucket, key):
    s3 = boto3.resource(
        "s3",
    )

    try:
        s3.Object(bucket, key).load()
        return True
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "404":
            print(f"File at s3://{bucket}/{key} does not exist")
        elif e.response["Error"]["Code"] == "403":
            print(f"Access denied for file s3://{bucket}/{key}")
        else:
            print(f"Failed to check existence of file s3://{bucket}/{key}: {e}")

    return False


def compare_faces(rek, source_bucket, source_key, target_bucket, target_key):
    response = rek.compare_faces(
        SourceImage={"S3Object": {"Bucket": source_bucket, "Name": source_key}},
        TargetImage={"S3Object": {"Bucket": target_bucket, "Name": target_key}},
        SimilarityThreshold=80,
        QualityFilter="HIGH",
    )

    try:
        for i, faces in enumerate(response["FaceMatches"]):
            print(
                f"Profile Pic to ID Face #{i+1} Similarity: {faces['Similarity']:.6f}"
            )
            print(f"\tQuality: {faces['Face']['Quality']}")
    except KeyError as e:
        print(f"{e}")

    return response["FaceMatches"]


def check_collection_exists(rek):
    try:
        collections = rek.list_collections(MaxResults=1)["CollectionIds"]
        if len(collections) == 0 or collections[0] != COLLECTION_ID:
            try:
                rek.create_collection(CollectionId=COLLECTION_ID)
            except Exception as e:
                print(f"Failed to create collection: {e}")
                return False
    except Exception as e:
        print(f"Failed to list collections: {e}")
        return False

    return True


def check_for_seen_face(rek, bucket, key):
    # First make sure the Collection exists
    if not check_collection_exists(rek):
        print("Failed to check collection existence")
        return []

    response = rek.search_faces_by_image(
        CollectionId=COLLECTION_ID,
        Image={"S3Object": {"Bucket": bucket, "Name": key}},
        MaxFaces=5,
        FaceMatchThreshold=90,
        QualityFilter="LOW",
    )

    try:
        for i, faces in enumerate(response["FaceMatches"]):
            print(f"Face #{i+1} Similarity: {faces['Similarity']:.6f}")
            print(f"\tFaceId: {faces['Face']['FaceId']}")
    except KeyError as e:
        print(f"{e}")

    return response["FaceMatches"]


def remove_faces_by_ids(face_ids):
    rek = boto3.client(
        "rekognition",
        region_name="us-east-1",
    )
    response = rek.delete_faces(
        CollectionId=COLLECTION_ID,
        FaceIds=face_ids,
    )

    print(response)
    return response


def remove_faces(event, context):
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
            continue

        if len(face_response["Faces"]) == 0:
            print("No faces to be deleted")
            continue

        response = rek.delete_faces(
            CollectionId=COLLECTION_ID,
            FaceIds=list(map(lambda x: x["FaceId"], face_response["Faces"])),
        )
        print(f"Deleted Faces: {response}")


# if __name__ == "__main__":
#     key = "public/profile-pics-under-review/8f8fcd8d-a6c1-4c81-ada9-3cff76f80ddf_Andrew_Sample_1973-01-07.jpg"
#     comps = key.split("/")
#     remove_key = f"public/profile-pictures/{comps}"

#     lambda_handler(
#         {
#             "Records": [
#                 {
#                     "s3": {
#                         "bucket": {"name": "adrenalinexxxxx153503-main"},
#                         "object": {"key": key},
#                     }
#                 }
#             ]
#         },
#         None,
#     )

#     remove_faces(
#         {
#             "Records": [
#                 {
#                     "s3": {
#                         "bucket": {"name": "adrenalinexxxxx153503-main"},
#                         "object": {"key": key},
#                     }
#                 }
#             ]
#         },
#         None,
#     )
#     remove_faces_by_ids(
#         ["dbd16f46-e67e-438d-9449-a56d00471df3", "d7dff4bb-dfeb-4fca-b94e-563eb4be6675"]
#     )
