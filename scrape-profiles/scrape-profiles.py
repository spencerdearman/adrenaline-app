from datetime import datetime
from concurrent.futures import as_completed
from requests_futures.sessions import FuturesSession
import re


def run():
    result = []
    baseLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number="

    session = FuturesSession()
    futures = []
    for i in range(24000, 150000):
        future = session.get(baseLink + str(i))
        future.i = i
        futures.append(future)

    start = datetime.now()
    last = start
    seen = set()

    with open("ids.csv", "a") as f:
        for future in as_completed(futures):
            response = future.result()
            # print(response.text)
            x = re.search("<strong>FINA Age: </strong>[0-9]+<br>", response.text)
            y = re.search(
                "<strong>High School Graduation:</strong> [0-9]+<br>", response.text
            )

            # Try to add by age first, if fails, try to add by grad year
            added = False

            if x is not None:
                age = x.group().split("</strong>")[-1][:-4]
                # gradYear = x.group().split("</strong> ")[-1][:-4]
                if 14 <= int(age) <= 18:
                    # print(gradYear)
                    # if 2024 <= int(gradYear) <= 2028:
                    result.append(future.i)
                    f.write(str(future.i) + "\n")
                    f.flush()
                    added = True

            # If we find grad year but didn't add them in age stage, proceed
            # We use grad year to capture athletes that may be FINA age 19, but
            # are eligible to compete 16-18 because they graduate with most kids
            # that age
            if y is not None and not added:
                # age = x.group().split("</strong>")[-1][:-4]
                gradYear = y.group().split("</strong> ")[-1][:-4]
                # if 14 <= int(age) <= 18:
                # print(gradYear)
                if 2024 <= int(gradYear) <= 2028:
                    result.append(future.i)
                    f.write(str(future.i) + "\n")
                    f.flush()

            seen.add(future.i)
            if not len(seen) % 100:
                print(
                    f"count={len(seen)}, Last run: {(datetime.now() - last).total_seconds():.2f}s, Elapsed: {(datetime.now() - start).total_seconds():.2f}s"
                )
                print(f"{result=}")
                last = datetime.now()


if __name__ == "__main__":
    run()
