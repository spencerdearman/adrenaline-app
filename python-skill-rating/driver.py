import boto3
from bs4 import BeautifulSoup
import bs4
import requests
from profile_parser import ProfileParser

# def updateDiveMeetsDivers(bucket_name):
#     s3_client = boto3.client('s3')
#     response = s3_client.list_objects_v2(Bucket=bucket_name)
#     assert 'Contents' in response
#     assert len(response['Contents']) > 0

#     objects = response['Contents']
#     latest_key = sorted(objects, key=lambda x: x['LastModified'], reverse=True)[0]

#     response = s3_client.get_object(Bucket=bucket_name, Key=latest_key)
#     assert 'Body' in response
#     body = response['Body']
#     parsedCSV = body.read().decode('utf-8').split()

#     try:
#         totalRows = len(parsedCSV)

#         for i, id in enumerate(parsedCSV):
#             p = ProfileParser()
#             p.parseProfile(diveMeetsID: id)

#             # Info is required for all personal data
#             if p.profileData.info is None:
#                 print(f"Could not get info from {id}")
#                 continue
#             info = p.profileData.info

#             # Gender is required for filtering
#             if info.gender is None:
#                 print(f"Could not get gender from {id}")
#                 continue
#             gender = info.gender

#             # Stats are required for calculating skill rating
#             if p.profileData.diveStatistics is None:
#                 print(f"Could not get stats from {id}")
#                 continue

#             stats = p.profileData.diveStatistics

#             # Compute skill rating with stats
#             let skillRating = SkillRating(diveStatistics: stats)
#             let (springboard, platform, total) = await skillRating.getSkillRating()

#             let obj = DiveMeetsDiver(id: id, firstName: info.first,
#                                         lastName: info.last, gender: gender,
#                                         finaAge: info.finaAge,
#                                         hsGradYear: info.hsGradYear,
#                                         springboardRating: springboard,
#                                         platformRating: platform, totalRating: total)

#             # Save object to DataStore
#             let _ = try await saveToDataStore(object: obj)

#             if i % 100 == 0 { print("\(i + 1) of \(totalRows) finished") }
#     except:
#         print("Failed to parse content")


if __name__ == "__main__":
    p = ProfileParser()
    if not p.parseProfileFromDiveMeetsID("56961"):
        print("Failed")
    else:
        print("Succeeded")
        print(p.profileData)
