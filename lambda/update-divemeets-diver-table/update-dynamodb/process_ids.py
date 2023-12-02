from profile_parser import ProfileParser
from skill_rating import SkillRating
import time
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
from cloudwatch import send_output, send_log_event
from util import DiveMeetsDiver, GraphqlClient


baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="


def process_ids(ids, cloudwatch_client, log_group_name, log_stream_name, isLocal):
    try:
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
                    time2 = time3
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
