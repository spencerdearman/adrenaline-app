import re
from typing import Optional
from bs4 import BeautifulSoup
import bs4
import requests
from util import ProfileData, ProfileInfoData, DiveStatistic


class ProfileParser:
    leadingLink = "https://secure.meetcontrol.com/divemeets/system/"

    def __init__(self):
        self.profileData = ProfileData()
        self.futureResult = None

    def __init__(self, response):
        self.profileData = ProfileData()
        self.futureResult = response

    def __wrapLooseText(self, text: str) -> str:
        try:
            # print(text)
            result: str = text
            pattern = "[a-zA-z0-9\\s&;:]+<br/>"
            matches = re.findall(pattern, text)
            # print(f"{matches=}")
            for match in matches:
                m = match.strip()[:-5]
                if len(m) > 0:
                    result = result.replace(match, f"<div>{m}</div><br/>")
            # print(result)
            return result
        except:
            print("Failed to parse text input")

        return ""

    def __assignInfoKeys(self, dict: dict[str, str]) -> Optional[ProfileInfoData]:
        result = ProfileInfoData()
        # print("Keys:", dict)
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
            # This case has to come first since it is more specific with "Age"
            elif "FINA Age:" in key:
                result.finaAge = int(value)
            elif "Age:" in key:
                result.age = int(value)
            elif "High School Graduation:" in key:
                result.hsGradYear = int(value)
            elif "DiveMeets #:" in key:
                result.diverId = value

        return result

    def __parseInfo(self, data: bs4.element.Tag) -> Optional[ProfileInfoData]:
        result: [str, str] = dict()

        # Add extra break to help with wrapping loose text
        dataHtml = str(data) + "<br/>"
        soup = BeautifulSoup(dataHtml, "html5lib")
        body = soup.find("body")
        if body is None:
            print("body is None")
            return None

        lastKey: str = ""
        rows = list(
            filter(lambda x: x.text != "" and x.name != "span", body.findChildren())
        )
        for row in rows:
            # print(row)
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
                if len(subRow) != 6:
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
                    numberOfTimes = int(subRow[5].text.strip())

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
                except ValueError:
                    print("ValueError")
                    return None
                except Exception as exc:
                    print("parseDiveStatistics:", exc)
                    return None

            return result
        except:
            print("Failed to parse dive statistics")

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
                return False

            soup = BeautifulSoup(response.content, "html.parser")
            tables = soup.find_all("td")
            if len(tables) == 0:
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
                    print("body None")
                    return False

                if "DiveMeets #" in body.text:
                    self.profileData.info = self.__parseInfo(body)
                elif "Dive Statistics" in body.text:
                    self.profileData.diveStatistics = self.__parseDiveStatistics(body)

            return True
        except Exception as exc:
            print(exc)
            return False

    def parseProfileFromDiveMeetsID(self, diveMeetsID: str) -> bool:
        return self.parseProfile(
            "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
            + diveMeetsID
        )
