import json
import boto3
from graphql import College, CoachUser, GraphqlClient

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
new_user_table = dynamodb.Table("NewUser-mwfmh6eukfhdhngcz756xxhxsa-main")
coach_user_table = dynamodb.Table("CoachUser-mwfmh6eukfhdhngcz756xxhxsa-main")


def lambda_handler(event, context):
    gq_client = GraphqlClient(
        endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
        headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
    )

    if "user_id" not in event or "college_id" not in event:
        print(
            "Failed to approve request. Missing required 'user_id' and/or 'college_id'"
        )
    user_id = event["user_id"]
    college_id = event["college_id"]

    get_college_response = gq_client.getCollegeById(college_id)
    print(f"College Get response: {get_college_response}")
    college = (
        None
        if get_college_response is None
        else College(get_college_response["data"]["getCollege"])
    )
    print(f"College: {None if college is None else college.toJSON()}")

    if get_college_response is None:
        with open("collegeLogos.json", "r", encoding="utf-8") as fd:
            college_logos = json.load(fd)

            with open("idsToNames.json", "r", encoding="utf-8") as f:
                ids_to_names = json.load(f)

                try:
                    create_response = gq_client.createCollege(
                        College(
                            {
                                "id": college_id,
                                "name": ids_to_names[college_id],
                                "imageLink": college_logos[ids_to_names[college_id]],
                                "coachID": None,
                            }
                        )
                    )
                    print(f"Create response: {create_response}")
                    if create_response is not None:
                        get_college_response = {
                            "data": {
                                "getCollege": create_response["data"]["createCollege"]
                            }
                        }
                    college = (
                        None
                        if create_response is None
                        else College(create_response["data"]["createCollege"])
                    )
                    print(
                        f"College after create: {None if college is None else college.toJSON()}"
                    )
                except KeyError as exc:
                    print(
                        f"KeyError while trying to run PutItem, aborting: {repr(exc)}"
                    )
                    return

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
    coach_user = CoachUser(coach_user_response["Item"])
    coach_user_version = coach_user._version
    old_college_id = coach_user.collegeID

    if old_college_id is not None and old_college_id != college_id:
        print("Old College ID: " + old_college_id)
        try:
            old_college_get_response = gq_client.getCollegeById(old_college_id)
            old_college = (
                None
                if old_college_get_response is None
                else College(old_college_get_response["data"]["getCollege"])
            )
            print("Old College: ", old_college.toJSON())
            old_college.coachID = None
            old_college_update_response = gq_client.updateCollege(
                old_college, old_college_get_response
            )
            print(f"Old College Update Response: {old_college_update_response}")
        except Exception as exc:
            print(f"Failed to remove coachID from college: {repr(exc)}")
            return

    coach_user.collegeID = college_id
    coach_user_update_response = gq_client.updateCoachUser(
        coach_user, coach_user_version
    )
    print(f"CoachUser: {coach_user_update_response}")

    college.coachID = coach_user.id
    college_update_response = gq_client.updateCollege(college, get_college_response)
    print(f"College: {college_update_response}")


if __name__ == "__main__":
    lambda_handler(
        {
            "user_id": "f629930a-9931-47d5-aaa3-93609e26444d",
            # "college_id": "abilene-christian-university",
            # "college_id": "university-of-chicago",
            "college_id": "brown-university",
        },
        None,
    )
