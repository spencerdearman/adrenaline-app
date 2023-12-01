import re
from typing import Optional
from bs4 import BeautifulSoup
import bs4
import requests
from util import ProfileData, ProfileInfoData, DiveStatistic
from cloudwatch import send_output, send_log_event


class ProfileParser:
    leadingLink = "https://secure.meetcontrol.com/divemeets/system/"

    def __init__(self):
        self.profileData = ProfileData()
        self.futureResult = None
        self.isLocal = True
        self.cloudwatch_client = None
        self.log_group_name = None
        self.log_stream_name = None

    def __init__(
        self, response, isLocal, cloudwatch_client, log_group_name, log_stream_name
    ):
        self.profileData = ProfileData()
        self.futureResult = response
        self.isLocal = isLocal
        self.cloudwatch_client = cloudwatch_client
        self.log_group_name = log_group_name
        self.log_stream_name = log_stream_name

    def __wrapLooseText(self, text: str) -> str:
        try:
            result: str = text
            pattern = "[a-zA-z0-9\\s&;:]+<br/>"
            matches = re.findall(pattern, text)

            for match in matches:
                m = match.strip()[:-5]
                if len(m) > 0:
                    result = result.replace(match, f"<div>{m}</div><br/>")

            return result
        except Exception as exc:
            send_output(
                self.isLocal,
                self.cloudwatch_client,
                self.log_group_name,
                self.log_stream_name,
                f"Failed to parse text input due to the following error: {exc}",
            )

        return ""

    def __assignInfoKeys(self, dict: dict[str, str]) -> Optional[ProfileInfoData]:
        result = ProfileInfoData()
        foundErrors = False

        for key, value in dict.items():
            if "Name:" in key:
                nameComps = value.split(" ")
                result.first = " ".join(nameComps[:-1])
                result.last = nameComps[-1]
            elif "City/State:" in key or "State:" in key:
                result.cityState = value
            elif "Country:" in key:
                result.country = value
            elif "Gender:" in key:
                result.gender = value.strip()
            elif "FINA Age:" in key:
                try:
                    result.finaAge = int(value)
                except ValueError as exc:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"ValueError: Failed to cast {value} to int for FINA age - {exc}",
                    )
                    foundErrors = True
            elif "Age:" in key:
                try:
                    result.age = int(value)
                except ValueError as exc:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"ValueError: Failed to cast {value} to int for age - {exc}",
                    )
                    foundErrors = True
            elif "High School Graduation:" in key:
                try:
                    result.hsGradYear = int(value)
                except ValueError as exc:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"ValueError: Failed to cast {value} to int for HS grad year - {exc}",
                    )
                    foundErrors = True
            elif "DiveMeets #:" in key:
                result.diverId = value

                if foundErrors:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"ValueErrors found for DiveMeets ID {value}",
                    )

        return result

    def __parseInfo(self, data: bs4.element.Tag) -> Optional[ProfileInfoData]:
        result: [str, str] = dict()

        # Add extra break to help with wrapping loose text
        dataHtml = str(data) + "<br/>"
        soup = BeautifulSoup(dataHtml, "html5lib")
        body = soup.find("body")
        if body is None:
            send_output(
                self.isLocal,
                self.cloudwatch_client,
                self.log_group_name,
                self.log_stream_name,
                f"parseInfo: body not found",
            )
            return None

        lastKey: str = ""
        rows = list(
            filter(lambda x: x.text != "" and x.name != "span", body.findChildren())
        )
        for row in rows:
            if row.name == "strong":
                lastKey = row.text.strip()
                continue
            elif row.name == "div":
                result[lastKey] = row.text.strip()

        return self.__assignInfoKeys(result)

    def __parseDiveStatistics(
        self, data: bs4.element.Tag
    ) -> Optional[list[DiveStatistic]]:
        try:
            result: [DiveStatistic] = []
            rows = data.find_all(lambda tag: tag.has_attr("bgcolor"))

            for row in rows:
                subRow = row.find_all("td")
                if len(subRow) < 6:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"parseDiveStatistics: length of subrows is less than 6",
                    )
                    return None

                try:
                    number = subRow[0].text.strip()
                    height = float(subRow[1].text[:-1].strip())
                    name = subRow[2].text.strip()
                    highScore = float(subRow[3].text.strip())
                    highScoreLink = self.leadingLink + (
                        subRow[3].find_all("a")[0].get("href").strip()
                    )
                    avgScore = float(subRow[4].text.strip())
                    avgScoreLink = self.leadingLink + (
                        subRow[4].find_all("a")[0].get("href").strip()
                    )

                    try:
                        numberOfTimes = int(subRow[5].text.strip())
                    except ValueError as exc:
                        send_output(
                            self.isLocal,
                            self.cloudwatch_client,
                            self.log_group_name,
                            self.log_stream_name,
                            f"ValueError: Failed to cast {subRow[5].text.strip()} for number of times - {exc}",
                        )

                    result.append(
                        DiveStatistic(
                            number,
                            name,
                            height,
                            highScore,
                            self.leadingLink + highScoreLink,
                            avgScore,
                            self.leadingLink + avgScoreLink,
                            numberOfTimes,
                        )
                    )
                except ValueError as exc:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"ValueError in parseDiveStatistics: {exc}",
                    )
                    return None
                except Exception as exc:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"Found exception in parseDiveStatistics: {exc}",
                    )
                    return None

            return result
        except:
            send_output(
                self.isLocal,
                self.cloudwatch_client,
                self.log_group_name,
                self.log_stream_name,
                f"Failed to parse dive statistics",
            )

        return None

    def __breakDownHtml(self, html: str) -> [str]:
        if "DiveMeets #" in html:
            return html.split("<br/><br/>")
        elif "Dive Statistics" in html and len(html.split("</table>")) > 1:
            comps = list(
                map(
                    lambda x: x + "</table>",
                    filter(lambda x: len(x) > 0, html.split("</table>")),
                )
            )

            return comps
        else:
            return [html]

    def parseProfile(self, link: str) -> bool:
        try:
            if self.futureResult is None:
                response = requests.get(link, timeout=5)
            else:
                response = self.futureResult
            if response.status_code // 100 != 2:
                send_output(
                    self.isLocal,
                    self.cloudwatch_client,
                    self.log_group_name,
                    self.log_stream_name,
                    f"response for {link.split('=')[-1]} returned non-200 status code",
                )
                return False

            soup = BeautifulSoup(response.content, "html.parser")
            tables = soup.find_all("td")
            if len(tables) == 0:
                send_output(
                    self.isLocal,
                    self.cloudwatch_client,
                    self.log_group_name,
                    self.log_stream_name,
                    f"parseProfile: tables list is empty",
                )
                return False

            data = tables[0]
            dataHtml = self.__wrapLooseText(
                str(data).replace("> <", "><").replace("\n", "")
            )

            bigHtmlBlocks = dataHtml.split("<br/><br/><br/><br/>")

            htmlComponents = []
            for elem in bigHtmlBlocks:
                htmlComponents += self.__breakDownHtml(elem)

            for elem in list(filter(lambda x: "img" not in x, htmlComponents)):
                soup = BeautifulSoup(elem, "html5lib")
                body = soup.find("body")

                if body is None:
                    send_output(
                        self.isLocal,
                        send_log_event,
                        self.cloudwatch_client,
                        self.log_group_name,
                        self.log_stream_name,
                        f"parseProfile: Info page body not found",
                    )
                    return False

                if "DiveMeets #" in body.text:
                    self.profileData.info = self.__parseInfo(body)
                elif "Dive Statistics" in body.text:
                    self.profileData.diveStatistics = self.__parseDiveStatistics(body)

            return True
        except Exception as exc:
            send_output(
                self.isLocal,
                self.cloudwatch_client,
                self.log_group_name,
                self.log_stream_name,
                f"Found exception in parseProfile: {exc}",
            )
            return False

    def parseProfileFromDiveMeetsID(self, diveMeetsID: str) -> bool:
        return self.parseProfile(
            "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
            + diveMeetsID
        )
