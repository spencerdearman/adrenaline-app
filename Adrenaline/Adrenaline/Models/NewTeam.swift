// swiftlint:disable all
import Amplify
import Foundation

public struct NewTeam: Model {
  public let id: String
  public var name: String
  internal var _coach: LazyReference<CoachUser>
  public var coach: CoachUser?   {
      get async throws { 
        try await _coach.get()
      } 
    }
  public var athletes: List<NewAthlete>?
  public var joinRequests: List<TeamJoinRequest>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var newTeamCoachId: String?
  
  public init(id: String = UUID().uuidString,
      name: String,
      coach: CoachUser? = nil,
      athletes: List<NewAthlete> = [],
      joinRequests: List<TeamJoinRequest> = [],
      newTeamCoachId: String? = nil) {
    self.init(id: id,
      name: name,
      coach: coach,
      athletes: athletes,
      joinRequests: joinRequests,
      createdAt: nil,
      updatedAt: nil,
      newTeamCoachId: newTeamCoachId)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      coach: CoachUser? = nil,
      athletes: List<NewAthlete> = [],
      joinRequests: List<TeamJoinRequest> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      newTeamCoachId: String? = nil) {
      self.id = id
      self.name = name
      self._coach = LazyReference(coach)
      self.athletes = athletes
      self.joinRequests = joinRequests
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.newTeamCoachId = newTeamCoachId
  }
  public mutating func setCoach(_ coach: CoachUser? = nil) {
    self._coach = LazyReference(coach)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      name = try values.decode(String.self, forKey: .name)
      _coach = try values.decodeIfPresent(LazyReference<CoachUser>.self, forKey: .coach) ?? LazyReference(identifiers: nil)
      athletes = try values.decodeIfPresent(List<NewAthlete>?.self, forKey: .athletes) ?? .init()
      joinRequests = try values.decodeIfPresent(List<TeamJoinRequest>?.self, forKey: .joinRequests) ?? .init()
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
      newTeamCoachId = try? values.decode(String?.self, forKey: .newTeamCoachId)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encode(_coach, forKey: .coach)
      try container.encode(athletes, forKey: .athletes)
      try container.encode(joinRequests, forKey: .joinRequests)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(newTeamCoachId, forKey: .newTeamCoachId)
  }
}