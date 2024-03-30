import boto3

MAIN_USER_POOL_ID = "us-east-1_pyXdsNweP"


def lambda_handler(event, context):
    if "userId" not in event:
        print("userId not provided, aborting...")
        return

    client = boto3.client("cognito-idp")
    user_id = event["userId"]

    try:
        if user_id == "ALL":
            response = client.list_users(UserPoolId=MAIN_USER_POOL_ID)
            # Get all users with UNCONFIRMED status
            unconfirmed_users = [
                x for x in response["Users"] if x["UserStatus"] == "UNCONFIRMED"
            ]

            # Get tuples of email and status
            user_data = [
                {
                    "email": list(
                        filter(lambda attr: attr["Name"] == "email", user["Attributes"])
                    )[0]["Value"],
                    "status": user["UserStatus"],
                }
                for user in unconfirmed_users
            ]

            for user in user_data:
                print(f"{user['email']}: {user['status']}")
                delete_response = client.admin_delete_user(
                    UserPoolId=MAIN_USER_POOL_ID, Username=user["email"]
                )
                if delete_response["ResponseMetadata"]["HTTPStatusCode"] != 200:
                    print(f"Delete user {user['email']} returned non-200 response")
        else:
            # Gets user by provided user id (this can be an email or authUserId)
            response = client.admin_get_user(
                UserPoolId=MAIN_USER_POOL_ID, Username=user_id
            )

            if response["UserStatus"] != "UNCONFIRMED":
                print("User has CONFIRMED status, ignoring...")
                return

            print(f"{user_id}: {response['UserStatus']}")
            delete_response = client.admin_delete_user(
                UserPoolId=MAIN_USER_POOL_ID, Username=user_id
            )
            if delete_response["ResponseMetadata"]["HTTPStatusCode"] != 200:
                print(f"Delete user {user_id} returned non-200 response")
    except Exception as exc:
        print(f"Failed to delete unconfirmed user(s) with input {event} - {repr(exc)}")
        return
    # print(response)
    # print(response["UserStatus"])


if __name__ == "__main__":
    # lambda_handler({"userId": "lsherwin10@gmail.com"}, None)
    # lambda_handler({"userId": "logansherwin@adren.tech"}, None)
    lambda_handler({"userId": "ALL"}, None)
