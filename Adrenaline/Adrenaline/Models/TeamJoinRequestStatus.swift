// swiftlint:disable all
import Amplify
import Foundation

public enum TeamJoinRequestStatus: String, EnumPersistable {
  case requestedByAthlete = "REQUESTED_BY_ATHLETE"
  case requestedByCoach = "REQUESTED_BY_COACH"
  case approved = "APPROVED"
  case deniedByAthlete = "DENIED_BY_ATHLETE"
  case deniedByCoachFirst = "DENIED_BY_COACH_FIRST"
  case deniedByCoachSecond = "DENIED_BY_COACH_SECOND"
  case deniedByCoachThird = "DENIED_BY_COACH_THIRD"
}