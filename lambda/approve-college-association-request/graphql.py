from datetime import datetime
from decimal import Decimal
import json
import time
import requests
import simplejson


class CoachUser:
    # def __init__(
    #     self,
    #     id,
    #     collegeID,
    #     newteamID,
    #     favoritesOrder,
    #     coachUserUserId,
    #     version=1,
    # ):
    #     self.id = id
    #     self.collegeID = collegeID
    #     self.newteamID = newteamID
    #     self.favoritesOrder = favoritesOrder
    #     self.coachuserUserId = coachUserUserId

    #     # Need below fields for DataStore compatibility
    #     self.createdAt = datetime.now().isoformat()
    #     self.updatedAt = datetime.now().isoformat()
    #     self.typename = "CoachUser"
    #     # lastChangedAt is stored in Unix Timestamp milliseconds
    #     self._lastChangedAt = int(time.time() * 1000.0)
    #     self._deleted = False
    #     self._version = version

    def __init__(self, in_dict: dict):
        assert isinstance(in_dict, dict)
        for key, val in in_dict.items():
            if isinstance(val, Decimal):
                spl = str(val).split(".")
                if len(spl) == 1:
                    setattr(self, key, int(spl[0]))
                else:
                    setattr(self, key, float(str(val)))
            elif isinstance(val, (list, tuple)):
                setattr(self, key, list(val))
            else:
                setattr(self, key, val)
        self._deleted = False
        if "collegeID" not in set(in_dict.keys()):
            self.collegeID = None
        if "newteamID" not in set(in_dict.keys()):
            self.newteamID = None
        if "_version" not in set(in_dict.keys()):
            self._version = 1

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class College:
    # def __init__(
    #     self,
    #     id,
    #     name,
    #     imageLink,
    #     coachID,
    #     version=1,
    # ):
    #     self.id = id
    #     self.name = name
    #     self.imageLink = imageLink
    #     self.athletes = []
    #     self.coachID = coachID

    #     # Need below fields for DataStore compatibility
    #     self.createdAt = datetime.now().isoformat()
    #     self.updatedAt = datetime.now().isoformat()
    #     self.typename = "College"
    #     # lastChangedAt is stored in Unix Timestamp milliseconds
    #     self._lastChangedAt = int(time.time() * 1000.0)
    #     self._deleted = False
    #     self._version = version

    def __init__(self, in_dict: dict):
        assert isinstance(in_dict, dict)
        for key, val in in_dict.items():
            if isinstance(val, Decimal):
                spl = str(val).split(".")
                if len(spl) == 1:
                    setattr(self, key, int(spl[0]))
                else:
                    setattr(self, key, float(str(val)))
            elif isinstance(val, (list, tuple)):
                setattr(self, key, list(val))
            else:
                setattr(self, key, val)
        self._deleted = False
        if "coachID" not in set(in_dict.keys()):
            self.coachID = None
        if "_version" not in set(in_dict.keys()):
            self._version = 1

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


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

    # This can throw an exception if execute() fails, so this needs to be caught
    def createCollege(self, college: College):
        create = """
mutation createCollege(
  $input: CreateCollegeInput!
  $condition: ModelCollegeConditionInput
) {
  createCollege(input: $input, condition: $condition) {
    id
    name
    imageLink
    athletes {
      nextToken
      startedAt
      __typename
    }
    coach {
      id
      favoritesOrder
      collegeID
      newteamID
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      coachUserUserId
      __typename
    }
    coachID
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
            "input": {
                "id": college.id,
                "name": college.name,
                "imageLink": college.imageLink,
                "coachID": college.coachID,
            }
        }

        return self.execute(
            query=create,
            operation_name="createCollege",
            variables=create_vars,
        )

    # This can throw an exception if execute() fails, so this needs to be caught
    def getCollegeById(self, id: str):
        getById = """
query getCollege($id: ID!) {
  getCollege(id: $id) {
    id
    name
    imageLink
    athletes {
      nextToken
      startedAt
      __typename
    }
    coach {
      id
      favoritesOrder
      collegeID
      newteamID
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      coachUserUserId
      __typename
    }
    coachID
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    __typename
  }
}
"""
        get_vars = {"id": id}

        result = self.execute(
            query=getById,
            operation_name="getCollege",
            variables=get_vars,
        )

        if result["data"]["getCollege"] is None:
            return None

        return result

    # This can throw an exception if execute() fails, so this needs to be caught
    def updateCollege(self, college: College, get_result):
        update = """
mutation updateCollege(
  $input: UpdateCollegeInput!
  $condition: ModelCollegeConditionInput
) {
  updateCollege(input: $input, condition: $condition) {
    id
    name
    imageLink
    athletes {
      nextToken
      startedAt
      __typename
    }
    coach {
      id
      favoritesOrder
      collegeID
      newteamID
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      coachUserUserId
      __typename
    }
    coachID
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
            or "getCollege" not in get_result["data"]
            or "_version" not in get_result["data"]["getCollege"]
        ):
            return f"Failed to update {college.id}, version not found in get_result"

        # Set the query version to allow conflict resolution in DynamoDB
        version = get_result["data"]["getCollege"]["_version"]

        update_vars = {
            "input": {
                "id": college.id,
                "name": college.name,
                "imageLink": college.imageLink,
                "coachID": college.coachID,
                "_version": version,
            }
        }

        return self.execute(
            query=update,
            operation_name="updateCollege",
            variables=update_vars,
        )

    # This can throw an exception if execute() fails, so this needs to be caught
    def deleteCollege(self, college: College):
        delete = """
mutation deleteCollege(
  $input: DeleteCollegeInput!
  $condition: ModelCollegeConditionInput
) {
  deleteCollege(input: $input, condition: $condition) {
    id
    name
    imageLink
    athletes {
      nextToken
      startedAt
      __typename
    }
    coach {
      id
      favoritesOrder
      collegeID
      newteamID
      createdAt
      updatedAt
      _version
      _deleted
      _lastChangedAt
      coachUserUserId
      __typename
    }
    coachID
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    __typename
  }
}
"""
        delete_vars = {
            "deleteCollegeInput": {
                "id": college.id,
                "_version": college._version,
            },
        }

        return self.execute(
            query=delete,
            operation_name="deleteCollege",
            variables=delete_vars,
        )

    #     def listDiveMeetsDivers(self):
    #         query = """
    # query listDiveMeetsDivers(
    #   $filter: ModelDiveMeetsDiverFilterInput
    #   $limit: Int
    #   $nextToken: String
    # ) {
    #   listDiveMeetsDivers(filter: $filter, limit: $limit, nextToken: $nextToken) {
    #     items {
    #       id
    #       firstName
    #       lastName
    #       gender
    #       finaAge
    #       hsGradYear
    #       springboardRating
    #       platformRating
    #       totalRating
    #       createdAt
    #       updatedAt
    #       _version
    #       _deleted
    #       _lastChangedAt
    #       __typename
    #     }
    #     nextToken
    #     startedAt
    #     __typename
    #   }
    # }
    # """

    #         return self.execute(
    #             query=query,
    #             operation_name="listDiveMeetsDivers",
    #         )

    # def update_dynamodb(
    #     self,
    #     college: College,
    # ):
    #     get_result = None

    #     try:
    #         get_result = self.getCollegeById(college.id)
    #     except requests.HTTPError as exc:
    #         print(
    #             f"Exception caught while trying to get College by ID {college.id} - {repr(exc)}"
    #         )
    #         return

    #     # Get request succeeded, but found a deleted record that has not yet
    #     # been removed by DynamoDB, so skip
    #     if get_result is not None and get_result["data"]["getCollege"]["_deleted"]:
    #         print("College is deleted, breaking...")
    #         return

    #     # Get request succeeded, but did not find an existing record
    #     if get_result is None:
    #         # Attempt to create the record
    #         try:
    #             result = self.createCollege(college)
    #         except requests.HTTPError as exc:
    #             print(
    #                 f"Exception caught while trying to create College {college.id} - {repr(exc)}",
    #             )

    #     # Get request succeeded and found an existing record
    #     else:
    #         # Attempt to update the existing record
    #         try:
    #             result = self.updateCollege(college, get_result)
    #         except requests.HTTPError as exc:
    #             print(
    #                 f"Exception caught while trying to update College {college.id} - {repr(exc)}",
    #             )

    # This can throw an exception if execute() fails, so this needs to be caught
    def updateCoachUser(self, coachUser: CoachUser, version):
        update = """
mutation updateCoachUser(
  $input: UpdateCoachUserInput!
  $condition: ModelCoachUserConditionInput
) {
  updateCoachUser(input: $input, condition: $condition) {
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
    favoritesOrder
    collegeID
    newteamID
    createdAt
    updatedAt
    _version
    _deleted
    _lastChangedAt
    coachUserUserId
    __typename
  }
}
"""

        update_vars = {
            "input": {
                "id": coachUser.id,
                "collegeID": coachUser.collegeID,
                "newteamID": coachUser.newteamID,
                "favoritesOrder": coachUser.favoritesOrder,
                "coachUserUserId": coachUser.coachUserUserId,
                "_version": version,
            }
        }

        return self.execute(
            query=update,
            operation_name="updateCoachUser",
            variables=update_vars,
        )
