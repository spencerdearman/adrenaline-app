from util import DiveMeetsDiver, GraphqlClient


def lambda_handler(event, context):
    gq_client = GraphqlClient(
        endpoint="https://xp3iidmppneeldz7sgtdn3ffme.appsync-api.us-east-1.amazonaws.com/graphql",
        headers={"x-api-key": "da2-ucgoxzk3hveplpbxkkl5woovq4"},
    )
    diver = DiveMeetsDiver(12, "Logan", "Sherwin", "M", 17, 2025, 1400.0, 0.0, 1400.0)
    # diver = DiveMeetsDiver(
    #     56961, "Anthony", "Sherwin", "M", 17, 2025, 1400.0, 0.0, 1400.0
    # )
    # diver = DiveMeetsDiver(
    #     21, "Spencer", "Dearman", "M", 17, 2025, 1200.0, 100.0, 1300.0
    # )

    get_result = gq_client.getDiveMeetsDiverById(diver.id)

    if get_result is None:
        print(f"creating {diver}")
        result = gq_client.createDiveMeetsDiver(diver)
    else:
        print(f"updating with {diver}")
        result = gq_client.updateDiveMeetsDiver(diver)

    print(result)


if __name__ == "__main__":
    lambda_handler(dict(), "")
