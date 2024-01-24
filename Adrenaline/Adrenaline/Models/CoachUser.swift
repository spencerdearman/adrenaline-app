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
  internal var _college: LazyReference<College>
  public var college: College?   {
      get async throws { 
        try await _college.get()
      } 
    }
  public var favoritesOrder: [Int]
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      user: NewUser? = nil,
      team: NewTeam? = nil,
      college: College? = nil,
      favoritesOrder: [Int] = []) {
    self.init(id: id,
      user: user,
      team: team,
      college: college,
      favoritesOrder: favoritesOrder,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      user: NewUser? = nil,
      team: NewTeam? = nil,
      college: College? = nil,
      favoritesOrder: [Int] = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._user = LazyReference(user)
      self._team = LazyReference(team)
      self._college = LazyReference(college)
      self.favoritesOrder = favoritesOrder
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setUser(_ user: NewUser? = nil) {
    self._user = LazyReference(user)
  }
  public mutating func setTeam(_ team: NewTeam? = nil) {
    self._team = LazyReference(team)
  }
  public mutating func setCollege(_ college: College? = nil) {
    self._college = LazyReference(college)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _user = try values.decodeIfPresent(LazyReference<NewUser>.self, forKey: .user) ?? LazyReference(identifiers: nil)
      _team = try values.decodeIfPresent(LazyReference<NewTeam>.self, forKey: .team) ?? LazyReference(identifiers: nil)
      _college = try values.decodeIfPresent(LazyReference<College>.self, forKey: .college) ?? LazyReference(identifiers: nil)
      favoritesOrder = try values.decode([Int].self, forKey: .favoritesOrder)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_user, forKey: .user)
      try container.encode(_team, forKey: .team)
      try container.encode(_college, forKey: .college)
      try container.encode(favoritesOrder, forKey: .favoritesOrder)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}