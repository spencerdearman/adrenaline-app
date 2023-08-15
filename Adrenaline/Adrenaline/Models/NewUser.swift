// swiftlint:disable all
import Amplify
import Foundation

public class NewUser: Model {
  public let id: String
  public var firstName: String
  public var lastName: String
  public var email: String
  public var phone: String?
  public var diveMeetsID: String?
  public var accountType: String
  public var athlete: NewAthlete?
  public var coach: Coach?
  public var followed: List<NewUserNewFollowed>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var newUserAthleteId: String?
  public var newUserCoachId: String?
  
    public convenience init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String,
      phone: String? = nil,
      diveMeetsID: String? = nil,
      accountType: String,
      athlete: NewAthlete? = nil,
      coach: Coach? = nil,
      followed: List<NewUserNewFollowed> = [],
      newUserAthleteId: String? = nil,
      newUserCoachId: String? = nil) {
    self.init(id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      diveMeetsID: diveMeetsID,
      accountType: accountType,
      athlete: athlete,
      coach: coach,
      followed: followed,
      createdAt: nil,
      updatedAt: nil,
      newUserAthleteId: newUserAthleteId,
      newUserCoachId: newUserCoachId)
  }
  internal init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String,
      phone: String? = nil,
      diveMeetsID: String? = nil,
      accountType: String,
      athlete: NewAthlete? = nil,
      coach: Coach? = nil,
      followed: List<NewUserNewFollowed> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      newUserAthleteId: String? = nil,
      newUserCoachId: String? = nil) {
      self.id = id
      self.firstName = firstName
      self.lastName = lastName
      self.email = email
      self.phone = phone
      self.diveMeetsID = diveMeetsID
      self.accountType = accountType
      self.athlete = athlete
      self.coach = coach
      self.followed = followed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.newUserAthleteId = newUserAthleteId
      self.newUserCoachId = newUserCoachId
  }
}
