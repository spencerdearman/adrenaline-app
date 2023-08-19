// swiftlint:disable all
import Amplify
import Foundation

public struct CoachUser: Model {
  public let id: String
  public var user: NewUser?
  public var team: NewTeam?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      user: NewUser? = nil,
      team: NewTeam? = nil) {
    self.init(id: id,
      user: user,
      team: team,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      user: NewUser? = nil,
      team: NewTeam? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.user = user
      self.team = team
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}