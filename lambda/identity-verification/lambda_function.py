import os
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

    print(event)
    records = event["Records"]

    for record in records:
        bucket = record["s3"]["bucket"]["name"]
        profilepic_s3_key = record["s3"]["object"]["key"]
        user_id = os.path.splitext(os.path.basename(profilepic_s3_key))[0]
        id_s3_key = f"public/id-cards/{user_id}.jpg"

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
            print("ERROR: User not found with matching face")
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
    profilepic_s3_bucket,
    profilepic_s3_key,
    user_id,
    id_s3_bucket,
    id_s3_key,
):
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
