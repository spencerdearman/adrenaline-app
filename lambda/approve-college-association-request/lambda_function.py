import json
import boto3

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
new_user_table = dynamodb.Table("NewUser-mwfmh6eukfhdhngcz756xxhxsa-main")
coach_user_table = dynamodb.Table("CoachUser-mwfmh6eukfhdhngcz756xxhxsa-main")
college_table = dynamodb.Table("College-mwfmh6eukfhdhngcz756xxhxsa-main")


def lambda_handler(event, context):
    if "user_id" not in event or "college_id" not in event:
        print(
            "Failed to approve request. Missing required 'user_id' and/or 'college_id'"
        )
    user_id = event["user_id"]
    college_id = event["college_id"]

    get_item_response = college_table.get_item(Key={"id": college_id})
    print(f"Get item response: {get_item_response}")

    # college = None
    if "Item" not in get_item_response:
        with open("collegeLogos.json", "r", encoding="utf-8") as fd:
            college_logos = json.load(fd)

            with open("idsToNames.json", "r", encoding="utf-8") as f:
                ids_to_names = json.load(f)

                try:
                    put_response = college_table.put_item(
                        Item={
                            "id": college_id,
                            "name": ids_to_names[college_id],
                            "imageLink": college_logos[college_id],
                        }
                    )
                    print(f"Put item response: {put_response}")
                    if "Item" not in put_response:
                        print("Failed to put item, aborting...")
                        return
                    # college = put_response["Item"]
                except KeyError as exc:
                    print(
                        f"KeyError while trying to run PutItem, aborting: {repr(exc)}"
                    )
                    return
    # else:
    # college = get_item_response["Item"]

    new_user_response = new_user_table.get_item(Key={"id": user_id})
    if "Item" not in new_user_response:
        print("Failed to get NewUser, aborting...")
        return

    new_user = new_user_response["Item"]
    if "newUserCoachId" not in new_user:
        print("NewUser does not have an associated CoachUser, aborting...")
        return

    coach_user_response = coach_user_table.get_item(
        Key={"id": new_user["newUserCoachId"]}
    )
    if "Item" not in coach_user_response:
        print("Failed to get CoachUser, aborting...")
        return
    coach_user = coach_user_response["Item"]
    old_college_id = coach_user.get("coachUserCollegeId", None)
    print("Old College ID: " + old_college_id)

    if old_college_id is not None:
        try:
            old_college_update_response = college_table.update_item(
                Key={"id": old_college_id},
                UpdateExpression="REMOVE collegeCoachId",
                ReturnValues="UPDATED_NEW",
            )
            print(f"Old College: {old_college_update_response}")
        except Exception as exc:
            print(f"Failed to remove collegeCoachId from college: {repr(exc)}")

    coach_user_update_response = coach_user_table.update_item(
        Key={"id": coach_user["id"]},
        UpdateExpression="SET coachUserCollegeId = :collegeId",
        ExpressionAttributeValues={":collegeId": college_id},
        ReturnValues="UPDATED_NEW",
    )
    print(f"CoachUser: {coach_user_update_response}")

    college_update_response = college_table.update_item(
        Key={"id": college_id},
        UpdateExpression="SET collegeCoachId = :coachId",
        ExpressionAttributeValues={":coachId": coach_user["id"]},
        ReturnValues="UPDATED_NEW",
    )
    print(f"College: {college_update_response}")


if __name__ == "__main__":
    lambda_handler(
        {
            "user_id": "f629930a-9931-47d5-aaa3-93609e26444d",
            # "college_id": "abilene-christian-university",
            "college_id": "university-of-chicago",
        },
        None,
    )
