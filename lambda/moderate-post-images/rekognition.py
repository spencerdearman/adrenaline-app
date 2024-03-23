def detect_moderation_labels(client, bucket, key):
    response = client.detect_moderation_labels(
        Image={"S3Object": {"Bucket": bucket, "Name": key}},
        MinConfidence=70,
    )

    print("Detecting moderation labels...")
    format_response(response)

    return has_no_inappropriate_content(response)


def format_response(response):
    if "ModerationLabels" in response and len(response["ModerationLabels"]) > 0:
        for detection in response["ModerationLabels"]:
            print(detection)
            print()
    elif "ModerationLabels" not in response:
        print("Could not find ModerationLabels key in response")
    else:
        print("No content was flagged in this image")


# Blocklist created by including relevant top-level or second-level category
# words, which should be captured by the label and parentName
def has_no_inappropriate_content(response):
    # https://docs.aws.amazon.com/rekognition/latest/dg/moderation.html#moderation-api
    blocklist = {
        "Explicit",
        "Partially Exposed Female Breast",
        "Implied Nudity",
        "Obstructed Intimate Parts",
        "Sexual Situations",
        "Violence",
        "Visually Disturbing",
        "Drugs & Tobacco",
        "Alcohol",
        "Gambling",
        "Hate Symbols",
    }

    if "ModerationLabels" not in response:
        print("Could not find ModerationLabels key")
        return False

    for detection in response["ModerationLabels"]:
        label = str(detection["Name"])
        parentName = str(detection["ParentName"])
        if label in blocklist or parentName in blocklist:
            return False

    return True
