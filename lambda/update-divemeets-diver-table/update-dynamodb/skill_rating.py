from typing import Optional, Callable
import json
from util import DiveStatistic
from profile_parser import ProfileParser


# {num: {"name": str, "dd": {[height]: float}}}
def getDiveTableData():
    try:
        with open("diveTable.json", "r", encoding="UTF-8") as f:
            return json.load(f)
    except Exception as exc:
        print(f"getDiveTableData: {repr(exc)}")
        return None


def getDiveDD(data, key: str, height: float) -> Optional[float]:
    if key not in data:
        return None
    diveData = data[key]

    # If value ends in .0, then convert to Int before converting to String, else convert
    # directly to String
    try:
        hInt = int(height)
        if float(hInt) == height:
            h = str(hInt)
        else:
            h = str(height)
    except ValueError:
        print(f"Failed to cast {height} for height in getDiveDD")

    # If height is in dd keys
    if h in diveData["dd"]:
        return diveData["dd"][h]

    return None


class SkillRating:
    def __init__(self, stats=None):
        self.diveStatistics: Optional[list[DiveStatistic]] = stats
        self.diveTableData = getDiveTableData()

    # Computes average score times DD for a given dive
    def __computeSkillValue(self, dive: DiveStatistic) -> float:
        if self.diveTableData is None:
            diveTableData = dict()
        else:
            diveTableData = self.diveTableData

        dd = getDiveDD(diveTableData, dive.number, dive.height)
        if dd is None:
            dd = 0.0

        return dive.avgScore * dd

    def __isSameDiveNumber(self, a: DiveStatistic, b: Optional[DiveStatistic]) -> bool:
        return b is not None and a.number[:-1] == b.number[:-1]

    def __getBestDive(
        self, dive: DiveStatistic, stored: Optional[DiveStatistic]
    ) -> Optional[DiveStatistic]:
        if stored is None:
            return dive

        diveValue = self.__computeSkillValue(dive)
        curValue = self.__computeSkillValue(stored)

        if diveValue > curValue or (
            diveValue == curValue and dive.numberOfTimes > stored.numberOfTimes
        ):
            return dive

        return stored

    # Gets top six dives from given set of statistics
    # Note: set of dives should be passed in after filtering by event
    def __getTopDives(self, dives: list[DiveStatistic]) -> list[DiveStatistic]:
        front: Optional[DiveStatistic] = None
        back: Optional[DiveStatistic] = None
        reverse: Optional[DiveStatistic] = None
        inward: Optional[DiveStatistic] = None
        twist: Optional[DiveStatistic] = None
        armstand: Optional[DiveStatistic] = None
        sixth: Optional[DiveStatistic] = None

        secondFront: Optional[DiveStatistic] = None
        secondBack: Optional[DiveStatistic] = None
        secondReverse: Optional[DiveStatistic] = None
        secondInward: Optional[DiveStatistic] = None
        secondTwist: Optional[DiveStatistic] = None
        secondArmstand: Optional[DiveStatistic] = None

        for dive in dives:
            firstNum = dive.number[0]
            if firstNum == "1":
                if front is None:
                    front = dive
                    continue

                f = front
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(f)

                # Incoming dive is best front seen so far
                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > f.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, front):
                        secondFront = front

                    front = dive
                    # Incoming dive is not better than best, but could be better than second
                    # best
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, front
                    ) and not self.__isSameDiveNumber(dive, secondFront):
                        secondFront = self.__getBestDive(dive, secondFront)
            elif firstNum == "2":
                if back is None:
                    back = dive
                    continue

                b = back
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(b)

                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > b.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, back):
                        secondBack = back

                    back = dive
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, back
                    ) and not self.__isSameDiveNumber(dive, secondBack):
                        secondBack = self.__getBestDive(dive, secondBack)
            elif firstNum == "3":
                if reverse is None:
                    reverse = dive
                    continue

                r = reverse
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(r)

                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > r.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, reverse):
                        secondReverse = reverse

                    reverse = dive
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, reverse
                    ) and not self.__isSameDiveNumber(dive, secondReverse):
                        secondReverse = self.__getBestDive(dive, secondReverse)
            elif firstNum == "4":
                if inward is None:
                    inward = dive
                    continue

                i = inward
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(i)

                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > i.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, inward):
                        secondInward = inward

                    inward = dive
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, inward
                    ) and not self.__isSameDiveNumber(dive, secondInward):
                        secondInward = self.__getBestDive(dive, secondInward)
            elif firstNum == "5":
                if twist is None:
                    twist = dive
                    continue

                t = twist
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(t)

                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > t.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, twist):
                        secondTwist = twist

                    twist = dive
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, twist
                    ) and not self.__isSameDiveNumber(dive, secondTwist):
                        secondTwist = self.__getBestDive(dive, secondTwist)
            elif firstNum == "6":
                if armstand is None:
                    armstand = dive
                    continue

                a = armstand
                diveValue = self.__computeSkillValue(dive)
                curValue = self.__computeSkillValue(a)

                if diveValue > curValue or (
                    diveValue == curValue and dive.numberOfTimes > a.numberOfTimes
                ):
                    # Only shifts down best into second best if they don't match dive nums,
                    # otherwise leaves second best empty
                    if not self.__isSameDiveNumber(dive, armstand):
                        secondArmstand = armstand

                    armstand = dive
                else:
                    # Only replaces second best if the dive nums are different
                    if not self.__isSameDiveNumber(
                        dive, armstand
                    ) and not self.__isSameDiveNumber(dive, secondArmstand):
                        secondArmstand = self.__getBestDive(dive, secondArmstand)

        for dive in [
            secondFront,
            secondBack,
            secondReverse,
            secondInward,
            secondTwist,
            secondArmstand,
        ]:
            if dive is None:
                continue
            sixth = self.__getBestDive(dive, sixth)

        final = [front, back, reverse, inward, twist, sixth]
        result: [DiveStatistic] = []
        for r in final:
            if r is None:
                continue
            result.append(r)

        return result

    # Separates ProfileDiveStatisticsData into three sets separated by event (1M, 3M, Platform)
    def __getDiverStatsByEvent(
        self,
    ) -> (list[DiveStatistic], list[DiveStatistic], list[DiveStatistic]):
        oneDives: list[DiveStatistic] = []
        threeDives: list[DiveStatistic] = []
        platformDives: list[DiveStatistic] = []

        if self.diveStatistics is None:
            print("getDiverStatsByEvent: Dive Statistics is None")
            return ([], [], [])

        for dive in self.diveStatistics:
            if dive.height > 3:
                platformDives.append(dive)
            elif dive.height > 1:
                threeDives.append(dive)
            else:
                oneDives.append(dive)

        return (oneDives, threeDives, platformDives)

    def __invertedNumberOfTimes(self, num: int) -> float:
        return 1.01 - (1.0 / float(num))

    def __computeMetric1(self, dives: list[DiveStatistic]) -> float:
        total: float = 0
        if self.diveTableData is None:
            diveTableData = dict()
        else:
            diveTableData = self.diveTableData

        for dive in dives:
            dd = getDiveDD(diveTableData, dive.number, dive.height)
            if dd is None:
                dd = 0.0

            total += (
                dive.avgScore * dd * self.__invertedNumberOfTimes(dive.numberOfTimes)
            )

        return total

    # Returns a triple of springboard rating, platform rating, and total rating
    def getSkillRatingFromDiveMeetsIDWithMetric(
        self, diveMeetsID: str, metric: Callable[[list[DiveStatistic]], float]
    ) -> (float, float, float):
        p = ProfileParser()

        p.parseProfileFromDiveMeetsID(diveMeetsID)
        if p.profileData.diveStatistics is None:
            print("Failed getting stats")
            return (0.0, 0.0, 0.0)

        return self.getSkillRatingWithStatsAndMetric(
            p.profileData.diveStatistics, metric
        )

    # Returns a triple of springboard rating, platform rating, and total rating using the default
    # computeMetric1 function
    # Note: This recomputes the diver statistics each time since this theoretically would be called
    # after an update from a meet
    def getSkillRatingFromDiveMeetsID(
        self, diveMeetsID: str
    ) -> (Optional[float], Optional[float], Optional[float]):
        p = ProfileParser()

        p.parseProfileFromDiveMeetsID(diveMeetsID)
        if p.profileData.diveStatistics is None:
            print("Failed getting stats")
            return (None, None, None)

        return self.getSkillRatingWithStatsAndMetric(
            p.profileData.diveStatistics, self.__computeMetric1
        )

    # Convenience function to avoid rerunning profile parsing when it is already set in init
    def getSkillRating(self) -> (Optional[float], Optional[float], Optional[float]):
        if self.diveStatistics == []:
            print(
                "This method should not be called without diveStatistics being set first"
            )
            return (None, None, None)

        return self.getSkillRatingWithStatsAndMetric(
            self.diveStatistics, self.__computeMetric1
        )

    def getSkillRatingWithStatsAndMetric(
        self, stats: list[DiveStatistic], metric: Callable[[list[DiveStatistic]], float]
    ) -> (float, float, float):
        skill = SkillRating(stats)
        divesByEvent = skill.__getDiverStatsByEvent()

        divesList = [
            ("1M", divesByEvent[0]),
            ("3M", divesByEvent[1]),
            ("Platform", divesByEvent[2]),
        ]

        springboard: float = 0.0
        platform: float = 0.0
        for event, dives in divesList:
            topDives = skill.__getTopDives(dives)
            eventRating = metric(topDives)
            if event == "Platform":
                platform += eventRating
            else:
                springboard += eventRating

        return (springboard, platform, springboard + platform)
