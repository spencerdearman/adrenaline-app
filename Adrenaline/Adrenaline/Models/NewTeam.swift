// swiftlint:disable all
import Amplify
import Foundation

public class NewTeam: Model {
  public let id: String
  public var name: String
  public var coach: CoachUser?
  public var athletes: List<NewAthlete>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var newTeamCoachId: String?
  
  public convenience init(id: String = UUID().uuidString,
      name: String,
      coach: CoachUser? = nil,
      athletes: List<NewAthlete> = [],
      newTeamCoachId: String? = nil) {
    self.init(id: id,
      name: name,
      coach: coach,
      athletes: athletes,
      createdAt: nil,
      updatedAt: nil,
      newTeamCoachId: newTeamCoachId)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      coach: CoachUser? = nil,
      athletes: List<NewAthlete> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      newTeamCoachId: String? = nil) {
      self.id = id
      self.name = name
      self.coach = coach
      self.athletes = athletes
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.newTeamCoachId = newTeamCoachId
  }
}
