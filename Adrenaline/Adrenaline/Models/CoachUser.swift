// swiftlint:disable all
import Amplify
import Foundation

public struct CoachUser: Model {
  public let id: String
  internal var _user: LazyReference<NewUser>
  public var user: NewUser?   {
      get async throws { 
        try await _user.get()
      } 
    }
  internal var _team: LazyReference<NewTeam>
  public var team: NewTeam?   {
      get async throws { 
        try await _team.get()
      } 
    }
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
      self._user = LazyReference(user)
      self._team = LazyReference(team)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setUser(_ user: NewUser? = nil) {
    self._user = LazyReference(user)
  }
  public mutating func setTeam(_ team: NewTeam? = nil) {
    self._team = LazyReference(team)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _user = try values.decodeIfPresent(LazyReference<NewUser>.self, forKey: .user) ?? LazyReference(identifiers: nil)
      _team = try values.decodeIfPresent(LazyReference<NewTeam>.self, forKey: .team) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_user, forKey: .user)
      try container.encode(_team, forKey: .team)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}