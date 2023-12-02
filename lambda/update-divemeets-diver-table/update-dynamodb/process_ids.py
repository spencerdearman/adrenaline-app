from profile_parser import ProfileParser
from skill_rating import SkillRating
import time
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
from cloudwatch import send_output, send_log_event
from util import DiveMeetsDiver, GraphqlClient
import boto3


baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="


# Filters out Adrenaline DiveMeets IDs from DiveMeetsDiver updates
def filter_adrenaline_profiles(ids):
    dynamodb_client = boto3.client("dynamodb", region_name="us-east-1")
    adrenalineIds = set()

    # Splits ids list into chunks of 150 elements since DDB scan requests are
    # limited on size of the FilterExpression
    chunks = []
    for i in range(0, len(ids), 150):
        if i + 150 < len(ids):
            chunks.append(ids[i : i + 150])
        else:
            chunks.append(ids[i:])

    for chunk in chunks:
        # Generates expressions to only return items that have matching diveMeetsIDs
        # in the input list
        expAttrValues = {f":{i}": {"S": id} for i, id in enumerate(chunk)}
        filterExpression = " OR ".join(
            [f"diveMeetsID = {key}" for key in expAttrValues.keys()]
        )

        response = dynamodb_client.scan(
            TableName="NewUser-mwfmh6eukfhdhngcz756xxhxsa-main",
            ExpressionAttributeValues=expAttrValues,
            ProjectionExpression="diveMeetsID",
            FilterExpression=filterExpression,
        )

        if "Items" not in response:
            continue

        # Set of all DiveMeets IDs that are registered under Adrenaline accounts
        adrenalineIds = adrenalineIds.union(
            set(map(lambda x: x["diveMeetsID"]["S"], response["Items"]))
        )

    # Removes Adrenaline DiveMeets IDs from DiveMeetsDiver IDs to be updated
    return list(set(ids).difference(adrenalineIds))


def process_ids(ids, cloudwatch_client, log_group_name, log_stream_name, isLocal):
    time1 = time.time()
    try:
        gq_client = GraphqlClient(
            endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
            headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
        )

        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"process_ids: Pre-filter ID count: {len(ids)}",
        )
        print(f"process_ids: Pre-filter ID count: {len(ids)}")

        # Filtering loses ordering of list, but this is not relevant to updating
        ids = sorted(filter_adrenaline_profiles(ids), key=lambda x: int(x))

        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"process_ids: Post-filter ID count: {len(ids)}",
        )
        print(f"process_ids: Post-filter ID count: {len(ids)}")

        totalRows = len(ids)
        session = FuturesSession()
        futures = []

        for i in ids:
            future = session.get(baseLink + str(i))
            future.i = i
            futures.append(future)

        time1 = time.time()
        time2 = time.time()
        for i, future in enumerate(as_completed(futures)):
            id = future.i
            try:
                data = future.result()
                p = ProfileParser(
                    data, isLocal, cloudwatch_client, log_group_name, log_stream_name
                )
                p.parseProfileFromDiveMeetsID(id)

                # Info is required for all personal data
                if p.profileData.info is None:
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"process_ids: [{i+1}/{totalRows}] Could not get info from {id}",
                    )
                    print(
                        f"process_ids: [{i+1}/{totalRows}] Could not get info from {id}"
                    )
                    continue
                info = p.profileData.info

                # Gender is required for filtering
                if info.gender is None:
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"process_ids: [{i+1}/{totalRows}] Could not get gender from {id}",
                    )
                    print(
                        f"process_ids: [{i+1}/{totalRows}] Could not get gender from {id}"
                    )
                    continue
                gender = info.gender

                # Stats are required for calculating skill rating
                if p.profileData.diveStatistics is None:
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"process_ids: [{i+1}/{totalRows}] Could not get stats from {id}",
                    )
                    print(
                        f"process_ids: [{i+1}/{totalRows}] Could not get stats from {id}"
                    )
                    continue

                stats = p.profileData.diveStatistics

                # Compute skill rating with stats
                skillRating = SkillRating(stats)
                springboard, platform, total = skillRating.getSkillRating()

                obj = DiveMeetsDiver(
                    id,
                    info.first,
                    info.last,
                    gender,
                    info.finaAge,
                    info.hsGradYear,
                    springboard,
                    platform,
                    total,
                )

                gq_client.update_dynamodb(
                    obj, cloudwatch_client, log_group_name, log_stream_name, isLocal
                )

            except Exception as exc:
                send_output(
                    isLocal,
                    send_log_event,
                    cloudwatch_client,
                    log_group_name,
                    log_stream_name,
                    f"process_ids: [{i+1}/{totalRows}] - {repr(exc)}",
                )
                print(f"process_ids: [{i+1}/{totalRows}] - {repr(exc)}")
            finally:
                if i != 0 and i % 100 == 0:
                    time3 = time.time()
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"[{i+1}/{totalRows}] Last 100: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s",
                    )
                    print(
                        f"[{i+1}/{totalRows}] Last 100: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s"
                    )
                    time2 = time3
                print(future.i)
    except Exception as exc:
        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"process_ids: Uncaught exception - {repr(exc)}",
        )

    send_output(
        isLocal,
        send_log_event,
        cloudwatch_client,
        log_group_name,
        log_stream_name,
        f"Took {time.time() - time1:.2f} s",
    )
