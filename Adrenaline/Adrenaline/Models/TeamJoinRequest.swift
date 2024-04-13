// swiftlint:disable all
import Amplify
import Foundation

public struct TeamJoinRequest: Model {
  public let id: String
  internal var _user: LazyReference<NewUser>
  public var user: NewUser   {
      get async throws { 
        try await _user.require()
      } 
    }
  internal var _team: LazyReference<NewTeam>
  public var team: NewTeam   {
      get async throws { 
        try await _team.require()
      } 
    }
  public var status: TeamJoinRequestStatus
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var teamJoinRequestUserId: String
  
  public init(id: String = UUID().uuidString,
      user: NewUser,
      team: NewTeam,
      status: TeamJoinRequestStatus,
      teamJoinRequestUserId: String) {
    self.init(id: id,
      user: user,
      team: team,
      status: status,
      createdAt: nil,
      updatedAt: nil,
      teamJoinRequestUserId: teamJoinRequestUserId)
  }
  internal init(id: String = UUID().uuidString,
      user: NewUser,
      team: NewTeam,
      status: TeamJoinRequestStatus,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      teamJoinRequestUserId: String) {
      self.id = id
      self._user = LazyReference(user)
      self._team = LazyReference(team)
      self.status = status
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.teamJoinRequestUserId = teamJoinRequestUserId
  }
  public mutating func setUser(_ user: NewUser) {
    self._user = LazyReference(user)
  }
  public mutating func setTeam(_ team: NewTeam) {
    self._team = LazyReference(team)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _user = try values.decodeIfPresent(LazyReference<NewUser>.self, forKey: .user) ?? LazyReference(identifiers: nil)
      _team = try values.decodeIfPresent(LazyReference<NewTeam>.self, forKey: .team) ?? LazyReference(identifiers: nil)
      status = try values.decode(TeamJoinRequestStatus.self, forKey: .status)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
      teamJoinRequestUserId = try values.decode(String.self, forKey: .teamJoinRequestUserId)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_user, forKey: .user)
      try container.encode(_team, forKey: .team)
      try container.encode(status, forKey: .status)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(teamJoinRequestUserId, forKey: .teamJoinRequestUserId)
  }
}