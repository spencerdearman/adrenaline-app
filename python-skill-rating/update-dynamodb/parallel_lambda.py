import boto3
from parallel_profile_parser import ProfileParser
from skill_rating import SkillRating
from decimal import Decimal
import json
from boto3.dynamodb.types import TypeSerializer
import os
import time
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
from cloudwatch import send_output, send_log_event, send_log_events


baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="


class DiveMeetsDiver:
    def __init__(
        self, id, first, last, gender, finaAge, hsGradYear, springboard, platform, total
    ):
        self.id = id
        self.firstName = first
        self.lastName = last
        self.gender = gender
        self.finaAge = finaAge
        self.hsGradYear = hsGradYear
        self.springboardRating = springboard
        self.platformRating = platform
        self.total = total

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


def process_csv(ids, cloudwatch_client, log_group_name, log_stream_name, isLocal):
    try:
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
                item = json.loads(obj.toJSON(), parse_float=Decimal)

                # To go from python to low-level format
                # https://stackoverflow.com/a/46738251/22068672
                serializer = TypeSerializer()
                low_level_copy = {k: serializer.serialize(v) for k, v in item.items()}
                # send_output(
                #     isLocal,
                #     send_log_event,
                #     cloudwatch_client,
                #     log_group_name,
                #     log_stream_name,
                #     f"Boto3 dict: {low_level_copy}",
                # )

                # Save object to DataStore
                dynamodb_client = boto3.client("dynamodb", "us-east-1")
                response = dynamodb_client.put_item(
                    TableName="DiveMeetsDiver-mwfmh6eukfhdhngcz756xxhxsa-main",
                    Item=low_level_copy,
                )
                print("Response:", response)

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
                if i % 10 == 0:
                    time3 = time.time()
                    send_output(
                        isLocal,
                        send_log_event,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        f"[{i}/{totalRows}] Last 10: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s",
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


# Used by lambda to get latest list of ids and process them
# def lambda_handler(event, context):
#     s3_client = boto3.client("s3")
#     bucket = os.environ["bucket_name"]
#     response = s3_client.list_objects_v2(Bucket=bucket)
#     assert "Contents" in response
#     assert len(response["Contents"]) > 0

#     # Get most recently updated CSV from DiveMeetsDiver python script
#     objects = response["Contents"]
#     latest_key = sorted(objects, key=lambda x: x["LastModified"], reverse=True)[0]

#     response = s3_client.get_object(Bucket=bucket, Key=latest_key["Key"])
#     assert "Body" in response
#     body = response["Body"]
#     parsedCSV = body.read().decode("utf-8").split()

#     process_csv(parsedCSV)
