import boto3
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
import re
import time
import json
import uuid


def process_data(future, response):
    result = -1
    # print(response.text)
    x = re.search("<strong>FINA Age: </strong>[0-9]+<br>", response.text)
    y = re.search("<strong>High School Graduation:</strong> [0-9]+<br>", response.text)

    if x is not None:
        age = x.group().split("</strong>")[-1][:-4]
        # gradYear = x.group().split("</strong> ")[-1][:-4]
        if 14 <= int(age) <= 18:
            # print(age)
            # if 2024 <= int(gradYear) <= 2028:
            result = future.i
            # print("Found age result:", result)
            # f.write(str(future.i) + "\n")
            # f.flush()

    # If we find grad year but didn't add them in age stage, proceed
    # We use grad year to capture athletes that may be FINA age 19, but
    # are eligible to compete 16-18 because they graduate with most kids
    # that age
    if y is not None and result == -1:
        # age = x.group().split("</strong>")[-1][:-4]
        gradYear = y.group().split("</strong> ")[-1][:-4]
        # if 14 <= int(age) <= 18:
        if 2024 <= int(gradYear) <= 2028:
            # print(gradYear)
            result = future.i
            # print("Found grad year result:", result)

    return result


def send_log_event(client, log_group_name, log_stream_name, message):
    client.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=[{"timestamp": int(round(time.time() * 1000)), "message": message}],
    )


def send_log_events(client, log_group_name, log_stream_name, messages):
    for message in messages:
        send_log_event(client, log_group_name, log_stream_name, message)


def init_cloudwatch(client, log_group_name, log_stream_name):
    try:
        client.create_log_group(
            logGroupName=log_group_name,
            tags={"Environment": "Production", "RetentionPeriod": "14"},
        )
    except:
        print(f"Log group {log_group_name} already exists")

    client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)


def send_output(isLocal, func, *args):
    if isLocal and type(args[-1]) == type([]):
        for elem in args[-1]:
            print(f"{elem}")
    elif isLocal:
        print(f"{args[-1]}")
    else:
        func(*args)


def run(event, isLocal=False):
    result = []
    outfile = "./ids.csv"
    region = "us-east-1"
    baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    cloudwatch_client = boto3.client("logs", region_name=region)
    log_group_name = "/aws/ec2/update-divemeets-diver-table"
    log_stream_name = f"python-script-logs-{uuid.uuid4()}"

    if not isLocal:
        init_cloudwatch(cloudwatch_client, log_group_name, log_stream_name)

    send_output(
        isLocal,
        send_log_event,
        cloudwatch_client,
        log_group_name,
        log_stream_name,
        f"{json.dumps(event)}",
    )

    assert "start_index" in event
    assert event["start_index"].isdigit()
    assert "end_index" in event
    assert event["end_index"].isdigit()

    session = FuturesSession()
    futures = []
    for i in range(int(event["start_index"]), int(event["end_index"]) + 1):
        future = session.get(baseLink + str(i))
        future.i = i
        futures.append(future)

    time1 = time.time()
    time2 = time.time()
    with open(outfile, "w") as f:
        out_count = 0
        last_out_count = out_count
        completed_runs = 0
        total_runs = int(event["end_index"]) - int(event["start_index"])

        for i, future in enumerate(as_completed(futures)):
            try:
                data = future.result()
                data = process_data(future, data)
            except:
                data = -1
            finally:
                if data != -1:
                    result.append(data)
                    out_count += 1
                    f.write(str(future.i) + "\n")

                completed_runs += 1

                if (i + 1) % 500 == 0:
                    time3 = time.time()

                    logs = [
                        f"[{completed_runs}/{total_runs}] Last 500: {time3-time2:.2f} s, Elapsed: {time3-time1:.2f} s"
                    ]
                    # Only prints updated out list if it has changed in last
                    # 500 indices
                    if last_out_count != out_count:
                        logs.append(f"Result to date: {result}")

                    send_output(
                        isLocal,
                        send_log_events,
                        cloudwatch_client,
                        log_group_name,
                        log_stream_name,
                        logs,
                    )

                    time2 = time3
                    last_out_count = out_count


if __name__ == "__main__":
    run({"start_index": "25000", "end_index": "150000"}, True)
