import re
from typing import Optional
from bs4 import BeautifulSoup
import bs4
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


class ProfileParser:
    def __init__(self):
        self.profileData = ProfileData()
        self.leadingLink = "https://secure.meetcontrol.com/divemeets/system/"

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
            # subs = re.sub(pattern, f"<div>{text}</div>", text)
            # print(f"{subs=}")
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
            elif "Age:" in key:
                result.age = int(value)
            elif "FINA Age:" in key:
                result.finaAge = int(value)
            elif "High School Graduation:" in key:
                result.hsGradYear = int(value)
            elif "DiveMeets #:" in key:
                result.diverId = value

        return result

    def __parseInfo(self, data: bs4.element.Tag) -> Optional[ProfileInfoData]:
        # try:
        result: [str, str] = dict()
        # print(data)
        # Add extra break to help with wrapping loose text
        dataHtml = str(data) + "<br/>"
        # guard let body = try SwiftSoup.parseBodyFragment(otherWrapLooseText(text: dataHtml)).body()
        # else { return nil }
        soup = BeautifulSoup(dataHtml, "html5lib")
        body = soup.find("body")
        if body is None:
            print("body is None")
            return None

        lastKey: str = ""
        # let rows = body.children().filter { $0.hasText() && $0.tagName() != "span" }
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
            response = requests.get(link, timeout=5)
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
