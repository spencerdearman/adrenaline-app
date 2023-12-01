from typing import Optional
from datetime import datetime, timedelta
from cloudwatch import send_output, send_log_event
import time
import json
import requests
import simplejson


def get_two_weeks_ahead_ttl():
    twoWeeksAhead = datetime.utcnow() + timedelta(days=14)
    return int(time.mktime(twoWeeksAhead.timetuple()))


class DiveMeetsDiver:
    def __init__(
        self,
        id,
        first,
        last,
        gender,
        finaAge,
        hsGradYear,
        springboard,
        platform,
        total,
        ttl=None,
    ):
        self.id = id
        self.firstName = first
        self.lastName = last
        self.gender = gender
        self.finaAge = finaAge
        self.hsGradYear = hsGradYear
        self.springboardRating = springboard
        self.platformRating = platform
        self.totalRating = total
        # ttl is stored in Unix Timestamp seconds
        if ttl is None:
            twoWeeksAhead = datetime.utcnow() + timedelta(days=14)
            self._ttl = get_two_weeks_ahead_ttl()
        else:
            self._ttl = int(ttl)

        # Need below fields for DataStore compatibility
        self.createdAt = datetime.now().isoformat()
        self.updatedAt = datetime.now().isoformat()
        self.typename = "DiveMeetsDiver"
        # lastChangedAt is stored in Unix Timestamp milliseconds
        self._lastChangedAt = int(time.time() * 1000.0)
        self._deleted = False
        self._version = 1

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class ProfileData:
    def __init__(self):
        self.info: Optional[ProfileInfoData] = None
        self.diveStatistics: Optional[list[DiveStatistic]] = None

    def __str__(self):
        if self.diveStatistics is not None:
            stats = f"{[str(x) for x in self.diveStatistics]}"
        else:
            stats = "None"

        return f"""ProfileData(
  Info: {self.info}
  Dive Statistics: {stats}      
)"""


class ProfileInfoData:
    def __init__(
        self,
        first="",
        last="",
        cityState=None,
        country=None,
        gender=None,
        age=None,
        finaAge=None,
        diverId=0,
        hsGradYear=None,
    ):
        self.first: str = first
        self.last: str = last
        self.cityState: Optional[str] = cityState
        self.country: Optional[str] = country
        self.gender: Optional[str] = gender
        self.age: Optional[int] = age
        self.finaAge: Optional[int] = finaAge
        self.diverId = diverId
        self.hsGradYear: Optional[int] = hsGradYear

    def __str__(self):
        return f"""ProfileInfoData(
  First: {self.first}
  Last: {self.last}
  CityState: {self.cityState}
  Country: {self.country}
  Gender: {self.gender}
  Age: {self.age}
  FINA Age: {self.finaAge}
  Diver ID: {self.diverId}
  HS Grad Year: {self.hsGradYear}
)"""


class DiveStatistic:
    def __init__(
        self,
        number,
        name,
        height,
        highScore,
        highScoreLink,
        avgScore,
        avgScoreLink,
        numberOfTimes,
    ):
        self.number: str = number
        self.name: str = name
        self.height: float = height
        self.highScore: float = highScore
        self.highScoreLink: str = highScoreLink
        self.avgScore: float = avgScore
        self.avgScoreLink: str = avgScoreLink
        self.numberOfTimes: int = numberOfTimes

    def __str__(self):
        return f"""DiveStatistic(
  Number: {self.number}
  Name: {self.name}
  Height: {self.height}
  High Score: {self.highScore}
  High Score Link: {self.highScoreLink}
  Avg Score: {self.avgScore}
  Avg Score Link: {self.avgScoreLink}
  # of Times: {self.numberOfTimes}
)"""


# https://sammart.in/post/2020-05-17-querying-appsync-with-python/
class GraphqlClient:
    def __init__(self, endpoint, headers):
        self.endpoint = endpoint
        self.headers = headers
        self.session = requests.Session()

    @staticmethod
    def serialization_helper(o):
        if isinstance(o, datetime):
            return o.strftime("%Y-%m-%dT%H:%M:%S.000Z")

    def execute(self, query, operation_name, variables={}):
        data = simplejson.dumps(
            {"query": query, "variables": variables, "operationName": operation_name},
            default=self.serialization_helper,
            ignore_nan=True,
        )

        response = self.session.request(
            url=self.endpoint,
            method="POST",
            headers=self.headers,
            json={
                "query": query,
                "variables": variables,
                "operationName": operation_name,
            },
        )

        return response.json()

    def createDiveMeetsDiver(self, diveMeetsDiver: DiveMeetsDiver):
        create = """
mutation createDiveMeetsDiver($createDiveMeetsDiverInput: CreateDiveMeetsDiverInput!,
                              $condition: ModelDiveMeetsDiverConditionInput) {
  createDiveMeetsDiver(input: $createDiveMeetsDiverInput, condition: $condition) {
    id
    firstName
    lastName
    gender
    finaAge
    hsGradYear
    springboardRating
    platformRating
    totalRating
    _ttl
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    __typename
  }
}
"""
        create_vars = {
            "createDiveMeetsDiverInput": {
                "id": diveMeetsDiver.id,
                "firstName": diveMeetsDiver.firstName,
                "lastName": diveMeetsDiver.lastName,
                "gender": diveMeetsDiver.gender,
                "finaAge": diveMeetsDiver.finaAge,
                "hsGradYear": diveMeetsDiver.hsGradYear,
                "springboardRating": diveMeetsDiver.springboardRating,
                "platformRating": diveMeetsDiver.platformRating,
                "totalRating": diveMeetsDiver.totalRating,
                "_ttl": get_two_weeks_ahead_ttl(),
            }
        }

        return self.execute(
            query=create,
            operation_name="createDiveMeetsDiver",
            variables=create_vars,
        )

    def getDiveMeetsDiverById(self, id: int):
        getById = """
query getDiveMeetsDiver($id: ID!) {
  getDiveMeetsDiver(id: $id) {
    id
    firstName
    lastName
    gender
    finaAge
    hsGradYear
    springboardRating
    platformRating
    totalRating
    _ttl
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    __typename
  }
}
"""
        get_vars = {"id": str(id)}

        result = self.execute(
            query=getById,
            operation_name="getDiveMeetsDiver",
            variables=get_vars,
        )

        if result["data"]["getDiveMeetsDiver"] is None:
            return None

        return result

    def updateDiveMeetsDiver(self, diveMeetsDiver: DiveMeetsDiver, get_result):
        update = """
mutation updateDiveMeetsDiver($updateDiveMeetsDiverInput: UpdateDiveMeetsDiverInput!,
                              $condition: ModelDiveMeetsDiverConditionInput) {
  updateDiveMeetsDiver(input: $updateDiveMeetsDiverInput, condition: $condition) {
    id
    firstName
    lastName
    gender
    finaAge
    hsGradYear
    springboardRating
    platformRating
    totalRating
    _ttl
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    __typename
  }
}
"""
        # Verify version is contained in get_result, else fail to update
        if (
            "data" not in get_result
            or "getDiveMeetsDiver" not in get_result["data"]
            or "_version" not in get_result["data"]["getDiveMeetsDiver"]
        ):
            return (
                f"Failed to update {diveMeetsDiver.id}, version not found in get_result"
            )

        # Set the query version to allow conflict resolution in DynamoDB
        version = get_result["data"]["getDiveMeetsDiver"]["_version"]

        update_vars = {
            "updateDiveMeetsDiverInput": {
                "id": diveMeetsDiver.id,
                "firstName": diveMeetsDiver.firstName,
                "lastName": diveMeetsDiver.lastName,
                "gender": diveMeetsDiver.gender,
                "finaAge": diveMeetsDiver.finaAge,
                "hsGradYear": diveMeetsDiver.hsGradYear,
                "springboardRating": diveMeetsDiver.springboardRating,
                "platformRating": diveMeetsDiver.platformRating,
                "totalRating": diveMeetsDiver.totalRating,
                "_version": version,
            }
        }

        return self.execute(
            query=update,
            operation_name="updateDiveMeetsDiver",
            variables=update_vars,
        )

    def update_dynamodb(
        self,
        diver: DiveMeetsDiver,
        cloudwatch_client=None,
        log_group_name=None,
        log_stream_name=None,
        isLocal=False,
    ):
        get_result = self.getDiveMeetsDiverById(diver.id)

        if get_result is None:
            send_output(
                isLocal,
                send_log_event,
                cloudwatch_client,
                log_group_name,
                log_stream_name,
                f"creating {diver.id}",
            )
            result = self.createDiveMeetsDiver(diver)
        else:
            send_output(
                isLocal,
                send_log_event,
                cloudwatch_client,
                log_group_name,
                log_stream_name,
                f"updating with {diver.id}",
            )
            result = self.updateDiveMeetsDiver(diver, get_result)

        send_output(
            isLocal,
            send_log_event,
            cloudwatch_client,
            log_group_name,
            log_stream_name,
            f"{result}",
        )
