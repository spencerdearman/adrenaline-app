// swiftlint:disable all
import Amplify
import Foundation

public struct College: Model {
  public let id: String
  public var name: String
  public var imageLink: String
  public var athletes: List<NewAthlete>?
  internal var _coach: LazyReference<CoachUser>
  public var coach: CoachUser?   {
      get async throws { 
        try await _coach.get()
      } 
    }
  public var coachID: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      imageLink: String,
      athletes: List<NewAthlete> = [],
      coach: CoachUser? = nil,
      coachID: String? = nil) {
    self.init(id: id,
      name: name,
      imageLink: imageLink,
      athletes: athletes,
      coach: coach,
      coachID: coachID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      imageLink: String,
      athletes: List<NewAthlete> = [],
      coach: CoachUser? = nil,
      coachID: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.imageLink = imageLink
      self.athletes = athletes
      self._coach = LazyReference(coach)
      self.coachID = coachID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setCoach(_ coach: CoachUser? = nil) {
    self._coach = LazyReference(coach)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      name = try values.decode(String.self, forKey: .name)
      imageLink = try values.decode(String.self, forKey: .imageLink)
      athletes = try values.decodeIfPresent(List<NewAthlete>?.self, forKey: .athletes) ?? .init()
      _coach = try values.decodeIfPresent(LazyReference<CoachUser>.self, forKey: .coach) ?? LazyReference(identifiers: nil)
      coachID = try? values.decode(String?.self, forKey: .coachID)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encode(imageLink, forKey: .imageLink)
      try container.encode(athletes, forKey: .athletes)
      try container.encode(_coach, forKey: .coach)
      try container.encode(coachID, forKey: .coachID)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}