from util import DiveMeetsDiver, GraphqlClient
from cloudwatch import send_output, send_log_event


def update_dynamodb(
    diver: DiveMeetsDiver,
    cloudwatch_client=None,
    log_group_name=None,
    log_stream_name=None,
    isLocal=False,
):
    # gq_client = GraphqlClient(
    #     endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
    #     headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
    # )

    get_result = gq_client.getDiveMeetsDiverById(diver.id)

    if get_result is None:
        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"creating {diver.id}",
        )
        result = gq_client.createDiveMeetsDiver(diver)
    else:
        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"updating with {diver.id}",
        )
        result = gq_client.updateDiveMeetsDiver(diver)

    send_output(
        isLocal,
        send_log_event,
        cloudwatch_client,
        log_group_name,
        log_stream_name,
        f"{result}",
    )


if __name__ == "__main__":
    diver = DiveMeetsDiver(12, "Logan", "Sherwin", "M", 17, 2025, 1400.0, 0.0, 1400.0)
    # diver = DiveMeetsDiver(
    #     56961, "Anthony", "Sherwin", "M", 17, 2025, 1400.0, 0.0, 1400.0
    # )
    # diver = DiveMeetsDiver(
    #     21, "Spencer", "Dearman", "M", 17, 2025, 1200.0, 100.0, 1300.0
    # )
    update_dynamodb(diver, isLocal=True)
