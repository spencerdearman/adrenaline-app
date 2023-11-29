# import boto3
from parallel_profile_parser import ProfileParser
from skill_rating import SkillRating

# from decimal import Decimal
# import json
# from boto3.dynamodb.types import TypeSerializer
import time
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
from cloudwatch import send_output, send_log_event
from util import DiveMeetsDiver, GraphqlClient


baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="


def process_csv(ids, cloudwatch_client, log_group_name, log_stream_name, isLocal):
    try:
        # dynamodb_client = boto3.client("dynamodb", "us-east-1")
        gq_client = GraphqlClient(
            endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
            headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
        )
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
                p = ProfileParser(data)
                p.parseProfileFromDiveMeetsID(id)

                # Info is required for all personal data
                if p.profileData.info is None:
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"Could not get info from {id}",
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
                        f"Could not get gender from {id}",
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
                        f"Could not get stats from {id}",
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
                # item = json.loads(obj.toJSON(), parse_float=Decimal)

                # To go from python to low-level format
                # https://stackoverflow.com/a/46738251/22068672
                # serializer = TypeSerializer()
                # low_level_copy = {k: serializer.serialize(v) for k, v in item.items()}

                # Fix typename key since serializer adds extra to front of it
                # when using __typename as variable name
                # low_level_copy["__typename"] = low_level_copy.pop("typename")

                # send_output(
                #     isLocal,
                #     send_log_event,
                #     cloudwatch_client,
                #     log_group_name,
                #     log_stream_name,
                #     f"Boto3 dict: {low_level_copy}",
                # )

                # Save object to DataStore
                # response = dynamodb_client.put_item(
                #     TableName="DiveMeetsDiver-mwfmh6eukfhdhngcz756xxhxsa-main",
                #     Item=low_level_copy,
                # )
                # send_output(
                #     isLocal,
                #     send_log_event,
                #     cloudwatch_client,
                #     log_group_name,
                #     log_stream_name,
                #     f"Response: {response}",
                # )

            except Exception as exc:
                send_output(
                    isLocal,
                    send_log_event,
                    cloudwatch_client,
                    log_group_name,
                    log_stream_name,
                    f"future process_csv: {exc}",
                )
            finally:
                if i % 100 == 0:
                    time3 = time.time()
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"[{i}/{totalRows}] Last 100: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s",
                    )
                    time2 = time3
    except Exception as exc:
        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"process_csv: {exc}",
        )

    send_output(
        isLocal,
        send_log_event,
        cloudwatch_client,
        log_group_name,
        log_stream_name,
        f"Took {time.time() - time1:.2f} s",
    )
