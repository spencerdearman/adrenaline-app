// swiftlint:disable all
import Amplify
import Foundation

public enum TeamJoinRequestStatus: String, EnumPersistable {
  case requestedByAthlete = "REQUESTED_BY_ATHLETE"
  case requestedByAthleteDeniedOnce = "REQUESTED_BY_ATHLETE_DENIED_ONCE"
  case requestedByAthleteDeniedTwice = "REQUESTED_BY_ATHLETE_DENIED_TWICE"
  case requestedByCoach = "REQUESTED_BY_COACH"
  case approved = "APPROVED"
  case deniedByAthlete = "DENIED_BY_ATHLETE"
  case deniedByCoachFirst = "DENIED_BY_COACH_FIRST"
  case deniedByCoachSecond = "DENIED_BY_COACH_SECOND"
  case deniedByCoachThird = "DENIED_BY_COACH_THIRD"
}