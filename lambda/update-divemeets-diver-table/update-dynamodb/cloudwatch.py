import time


def init_cloudwatch_logs(client, log_group_name, log_stream_name):
    try:
        client.create_log_group(
            logGroupName=log_group_name,
            tags={"Environment": "Production", "RetentionPeriod": "14"},
        )
    except:
        print(f"Log group {log_group_name} already exists")

    client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)


def send_log_event(client, log_group_name, log_stream_name, message):
    client.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=[{"timestamp": int(round(time.time() * 1000)), "message": message}],
    )


def send_log_events(client, log_group_name, log_stream_name, messages):
    for message in messages:
        send_log_event(client, log_group_name, log_stream_name, message)


def send_output(isLocal, func, *args):
    if isLocal and type(args[-1]) == type([]):
        for elem in args[-1]:
            print(f"{elem}")
    elif isLocal:
        print(f"{args[-1]}")
    else:
        func(*args)
