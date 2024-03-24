import time
from concurrent.futures import as_completed
import copy
import boto3
from boto3.dynamodb.conditions import Attr
from profile_parser import ProfileParser
from skill_rating import SkillRating
from requests_futures.sessions import FuturesSession
from graphql import GraphqlClient

dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
new_user_table = dynamodb.Table("NewUser-mwfmh6eukfhdhngcz756xxhxsa-main")
NEW_ATHLETE_TABLE = "NewAthlete-mwfmh6eukfhdhngcz756xxhxsa-main"
baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="


def lambda_handler(event, context):
    gq_client = GraphqlClient(
        endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
        headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
    )

    scan_response = new_user_table.scan(
        FilterExpression=Attr("diveMeetsID").exists()
        & Attr("accountType").eq("Athlete")
    )
    data = scan_response["Items"]

    while "LastEvaluatedKey" in scan_response:
        scan_response = new_user_table.scan(
            ExclusiveStartKey=scan_response["LastEvaluatedKey"]
        )
        data.extend(scan_response["Items"])

    athlete_ids = {
        x["newUserAthleteId"]: x["diveMeetsID"] for x in data if "newUserAthleteId" in x
    }

    batch_get_response = dynamodb.batch_get_item(
        RequestItems={
            NEW_ATHLETE_TABLE: {
                "Keys": [{"id": x} for x in athlete_ids.keys()],
                "ConsistentRead": True,
            }
        }
    )

    divemeets_ids_to_athletes = {
        athlete_ids[row["id"]]: row
        for row in batch_get_response["Responses"][NEW_ATHLETE_TABLE]
    }
    print(f"To be processed: {divemeets_ids_to_athletes}")

    process_divemeets_ids(gq_client, divemeets_ids_to_athletes)


# Takes in GraphQL Client and dict of {DiveMeets ID: NewAthlete dict}
def process_divemeets_ids(gq_client, divemeets_ids_to_athletes):
    totalRows = len(divemeets_ids_to_athletes.keys())
    session = FuturesSession()
    futures = []

    for i in divemeets_ids_to_athletes.keys():
        future = session.get(baseLink + str(i))
        future.i = i
        futures.append(future)

    time1 = time.time()
    time2 = time.time()
    for i, future in enumerate(as_completed(futures)):
        dm_id = future.i
        try:
            data = future.result()
            p = ProfileParser(data)
            p.parseProfileFromDiveMeetsID(dm_id)

            # Stats are required for calculating skill rating
            if p.profileData.diveStatistics is None:
                print(
                    f"process_ids: [{i+1}/{totalRows}] Could not get stats from {dm_id}"
                )
                continue

            stats = p.profileData.diveStatistics

            # Compute skill rating with stats
            skillRating = SkillRating(stats)
            springboard, platform, total = skillRating.getSkillRating()
            new_athlete = copy.deepcopy(divemeets_ids_to_athletes[dm_id])
            new_athlete["springboardRating"] = springboard
            new_athlete["platformRating"] = platform
            new_athlete["totalRating"] = total

            old_athlete = divemeets_ids_to_athletes[dm_id]

            print("Updated Athlete: ", new_athlete)
            print("Old Athlete: ", old_athlete)

            gq_client.updateNewAthlete(new_athlete)
        except Exception as exc:
            print(f"process_ids: [{i+1}/{totalRows}] - {repr(exc)}")
        finally:
            if i != 0 and i % 100 == 0:
                time3 = time.time()
                print(
                    f"[{i+1}/{totalRows}] Last 100: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s",
                )
                time2 = time3


if __name__ == "__main__":
    lambda_handler(None, None)
