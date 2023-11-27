import boto3
from profile_parser import ProfileParser
from skill_rating import SkillRating
from decimal import Decimal
import json
from boto3.dynamodb.types import TypeSerializer
import os


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

    def stringDict(self, item):
        return {"S": item}

    def floatDict(self, item):
        return {}

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)

    # def dict(self):
    #     return {"id": self.stringDict(self.id),
    #             "firstName": self.stringDict(self.firstName),
    #             "lastName": self.stringDict(self.lastName),
    #             "gender": self.stringDict(self.gender),
    #             "finaAge": self.stringDict(self.id),
    #             "hsGradYear": self.stringDict(self.id),
    #             "springboardRating": self.stringDict(self.id),
    #             "platformRating": self.stringDict(self.id),
    #             "totalRating": self.stringDict(self.id),}


def lambda_handler(event, context):
    s3_client = boto3.client("s3")
    bucket = os.environ["bucket_name"]
    response = s3_client.list_objects_v2(Bucket=bucket)
    assert "Contents" in response
    assert len(response["Contents"]) > 0

    # Get most recently updated CSV from DiveMeetsDiver python script
    objects = response["Contents"]
    latest_key = sorted(objects, key=lambda x: x["LastModified"], reverse=True)[0]

    response = s3_client.get_object(Bucket=bucket, Key=latest_key)
    assert "Body" in response
    body = response["Body"]
    parsedCSV = body.read().decode("utf-8").split()

    try:
        totalRows = len(parsedCSV)

        # for i, id in enumerate(parsedCSV):
        for i, id in enumerate(parsedCSV):
            p = ProfileParser()
            p.parseProfileFromDiveMeetsID(id)

            # Info is required for all personal data
            if p.profileData.info is None:
                print(f"Could not get info from {id}")
                continue
            info = p.profileData.info

            # Gender is required for filtering
            if info.gender is None:
                print(f"Could not get gender from {id}")
                continue
            gender = info.gender

            # Stats are required for calculating skill rating
            if p.profileData.diveStatistics is None:
                print(f"Could not get stats from {id}")
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
            print(low_level_copy)

            # Save object to DataStore
            # let _ = try await saveToDataStore(object: obj)
            dynamodb_client = boto3.client("dynamodb", "us-east-1")
            response = dynamodb_client.put_item(
                TableName="DiveMeetsDiver", Item=low_level_copy
            )
            print(response)

            if i % 100 == 0:
                print(f"{i + 1} of {totalRows} finished")
    except Exception as exc:
        print(f"updateDiveMeetsDivers: {exc}")
