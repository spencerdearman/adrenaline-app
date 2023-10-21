import cv2
import os
import boto3
from botocore.exceptions import NoCredentialsError
import shutil
import json


def countBlackPixelsInRow(frame, start, end, limit):
    """
    This is not being used, but it is kept for potential future use.
    Returns max counted black pixels if it gets stopped before the end of the
    row and exceeds the limit, else returns None
    """
    # Accessing BGR pixel values
    consec_black_pixels = 0
    step = 1 if start < end else -1
    for x in range(start, end, step):
        b = frame[0, x, 0]  # B Channel Value
        g = frame[0, x, 1]  # G Channel Value
        r = frame[0, x, 2]  # R Channel Value

        if r == g == b == 0:
            consec_black_pixels += 1
        else:
            if consec_black_pixels >= limit:
                break
            else:
                consec_black_pixels = 0

        if x == end - step:
            return None

    return consec_black_pixels


def detectVerticalVideoAndCrop(frame, widthCrop=None):
    """
    This is not being used, but it is kept for potential future use.
    Takes in a filename and frame and returns a (potentially) cropped frame if
    it is thought to be a vertical video with improper aspect ratio. If frame is
    not a vertical frame with landscape orientation, returns None"""
    # Get frame height and width to access pixels
    height, width, _ = frame.shape

    diff = width - height
    max_black_pixels = diff // 2

    if widthCrop is None:
        lh_consec_black_pixels = countBlackPixelsInRow(
            frame, 0, width, max_black_pixels
        )
        rh_consec_black_pixels = countBlackPixelsInRow(
            frame, width - 1, -1, max_black_pixels
        )

        if lh_consec_black_pixels is None or rh_consec_black_pixels is None:
            widthCrop = None
        else:
            widthCrop = max(lh_consec_black_pixels, rh_consec_black_pixels)

    if widthCrop is not None:
        cropped = frame[0:height, widthCrop : width - widthCrop]
    else:
        cropped = None
        print("cropped is None")

    return cropped, widthCrop


def cropVideo(cap, output_filename):
    """
    This is not being used, but it is kept for potential future use."""
    cap.set(1, 2)
    writer = None
    widthCrop = None
    is_landscape = False

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Reached end of frames, returning...")
            break

        # Get frame height and width to access pixels
        height, width, _ = frame.shape

        diff = width - height
        is_vertical_video = diff < 0

        # If video doesn't have extra black space on edges, skips cropping
        # This also leaves widthCrop as None, which provides context in return
        if is_vertical_video:
            break

        cropped, widthCrop = detectVerticalVideoAndCrop(frame, widthCrop)

        # cropped would only be None in the case where it did not reach the
        # max black pixel count on the edges, meaning it is a landscape video
        if cropped is None:
            is_landscape = True
            print("Video is landscape, ending early...")
            break

        if writer is None:
            writer = cv2.VideoWriter(
                output_filename,
                cv2.VideoWriter_fourcc(*"mp4v"),
                cap.get(cv2.CAP_PROP_FPS),
                (cropped.shape[1], cropped.shape[0]),
            )

        if writer is not None and cropped is not None:
            writer.write(cropped)

    cap.release()

    if writer is not None:
        writer.release()

    return widthCrop, is_landscape


# https://stackoverflow.com/a/185941/22068672
def deleteTempFiles():
    """
    This is not being used, but it is kept for potential future use."""
    folder = "/tmp"
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print("Failed to delete %s. Reason: %s" % (file_path, e))


def checkVerticalVideo_old(bucket, key):
    """
    This is not being used, but it is kept for potential future use.
    Pulls video from S3 bucket, checks if it is vertical without extra black
    space, and if it is not, crops the video and reuploads to S3. Returns
    True if video is vertical and False if it is a true landscape video"""
    s3 = boto3.client("s3")

    url = s3.generate_presigned_url(
        ClientMethod="get_object", Params={"Bucket": bucket, "Key": key}
    )
    cap = cv2.VideoCapture(url)
    print("Successfully created video capture from S3")

    filename = os.path.splitext(os.path.basename(key))[0]
    output_filename = f"/tmp/{filename}_cropped.mp4"
    print(f"Output filename: {output_filename}")

    widthCrop, is_landscape = cropVideo(cap, output_filename)
    print(f"Already Vertical? {widthCrop is None}")
    print(f"True landscape? {is_landscape}")

    inputParams = {"bucket": bucket, "key": key}

    reattach_audio_bucket = "adrenaline-reattach-audio"

    # If widthCrop is not None, then the video was processed and the S3 input
    # needs to be updated with the cropped version
    if widthCrop is not None:
        try:
            s3.upload_file(output_filename, reattach_audio_bucket, key)
            print("Successfully uploaded back to S3")

            client = boto3.client("lambda")
            response = client.invoke(
                FunctionName="arn:aws:lambda:us-east-1:861465534182:function:reattach-audio",
                InvocationType="RequestResponse",
                Payload=json.dumps(inputParams),
            )

            responseFromChild = json.load(response["Payload"])
            print(
                f"Response from child (Status Code {responseFromChild['statusCode']}):",
                responseFromChild["body"],
            )

            if responseFromChild["statusCode"] != 200:
                return None
        except FileNotFoundError:
            print(f"The file {output_filename} was not found")
            return None
        except NoCredentialsError:
            print("Credentials not available")
            return None

    deleteTempFiles()

    return not is_landscape


def checkVerticalVideo(bucket, key):
    """
    Pulls video from S3 bucket, checks if it is portrait or landscape. Returns
    True if video is vertical and False if it is a true landscape video"""
    s3 = boto3.client("s3")

    url = s3.generate_presigned_url(
        ClientMethod="get_object", Params={"Bucket": bucket, "Key": key}
    )
    cap = cv2.VideoCapture(url)
    print("Successfully created video capture from S3")

    ret, frame = cap.read()
    if not ret:
        print("No frames found, returning None...")
        return None

    # Get frame height and width to access pixels
    height, width, _ = frame.shape
    print(f"Width: {width}, Height: {height}")

    # If width - height < 0, then video is taller than it is wide => portrait
    return (width - height) < 0
