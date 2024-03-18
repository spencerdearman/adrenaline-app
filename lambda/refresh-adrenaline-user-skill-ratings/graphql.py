from typing import Optional
from datetime import datetime
from decimal import Decimal
import simplejson
import requests


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
        elif isinstance(o, Decimal):
            return str(o)
        return ""

    # This can throw an exception if the request fails, so calls to this need to
    # handle exceptions gracefully
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
            data=data,
        )

        # If response is non-200 status code, throw exception
        response.raise_for_status()

        return response.json()

    # !!This uses GraphQL dictionaries instead of objects!!
    # This can throw an exception if execute() fails, so this needs to be caught
    def updateNewAthlete(self, newAthlete):
        update = """
mutation updateNewAthlete(
  $input: UpdateNewAthleteInput!
  $condition: ModelNewAthleteConditionInput
) {
  updateNewAthlete(input: $input, condition: $condition) {
    id
    user {
      id
      firstName
      lastName
      email
      phone
      diveMeetsID
      accountType
      dateOfBirth
      tokens
      favoritesIds
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      newUserAthleteId
      newUserCoachId
      __typename
    }
    team {
      id
      name
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      newTeamCoachId
      __typename
    }
    college {
      id
      name
      imageLink
      coachID
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      __typename
    }
    academics {
      id
      satScore
      actScore
      weightedGPA
      gpaScale
      coursework
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      academicRecordAthleteId
      __typename
    }
    heightFeet
    heightInches
    weight
    weightUnit
    gender
    graduationYear
    highSchool
    hometown
    springboardRating
    platformRating
    totalRating
    dives {
      nextToken
      startedAt
      __typename
    }
    collegeID
    newteamID
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    newAthleteAcademicsId
    newAthleteUserId
    __typename
  }
}
"""
        update_vars = {
            "input": {
                "id": newAthlete["id"],
                "heightFeet": newAthlete.get("heightFeet", None),
                "heightInches": newAthlete.get("heightInches", None),
                "weight": newAthlete.get("weight", None),
                "weightUnit": newAthlete.get("weightUnit", None),
                "gender": newAthlete.get("gender", None),
                "graduationYear": newAthlete.get("graduationYear", None),
                "highSchool": newAthlete.get("highSchool", None),
                "hometown": newAthlete.get("hometown", None),
                "springboardRating": newAthlete.get("springboardRating", None),
                "platformRating": newAthlete.get("platformRating", None),
                "totalRating": newAthlete.get("totalRating", None),
                "collegeID": newAthlete.get("collegeID", None),
                "newteamID": newAthlete.get("newteamID", None),
                "newAthleteAcademicsId": newAthlete.get("newAthleteAcademicsId", None),
                "newAthleteUserId": newAthlete.get("newAthleteUserId", None),
                "_version": newAthlete["_version"],
            }
        }

        return self.execute(
            query=update,
            operation_name="updateNewAthlete",
            variables=update_vars,
        )
