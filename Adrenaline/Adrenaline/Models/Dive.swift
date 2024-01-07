// swiftlint:disable all
import Amplify
import Foundation

public struct Dive: Model {
  public let id: String
  internal var _event: LazyReference<NewEvent>
  public var event: NewEvent   {
      get async throws { 
        try await _event.require()
      } 
    }
  internal var _athlete: LazyReference<NewAthlete>
  public var athlete: NewAthlete   {
      get async throws { 
        try await _athlete.require()
      } 
    }
  public var number: String
  public var name: String
  public var height: Double
  public var netScore: Double
  public var dd: Double
  public var totalScore: Double
  public var scores: List<JudgeScore>?
  public var newathleteID: String
  public var neweventID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      event: NewEvent,
      athlete: NewAthlete,
      number: String,
      name: String,
      height: Double,
      netScore: Double,
      dd: Double,
      totalScore: Double,
      scores: List<JudgeScore> = [],
      newathleteID: String,
      neweventID: String) {
    self.init(id: id,
      event: event,
      athlete: athlete,
      number: number,
      name: name,
      height: height,
      netScore: netScore,
      dd: dd,
      totalScore: totalScore,
      scores: scores,
      newathleteID: newathleteID,
      neweventID: neweventID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      event: NewEvent,
      athlete: NewAthlete,
      number: String,
      name: String,
      height: Double,
      netScore: Double,
      dd: Double,
      totalScore: Double,
      scores: List<JudgeScore> = [],
      newathleteID: String,
      neweventID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._event = LazyReference(event)
      self._athlete = LazyReference(athlete)
      self.number = number
      self.name = name
      self.height = height
      self.netScore = netScore
      self.dd = dd
      self.totalScore = totalScore
      self.scores = scores
      self.newathleteID = newathleteID
      self.neweventID = neweventID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setEvent(_ event: NewEvent) {
    self._event = LazyReference(event)
  }
  public mutating func setAthlete(_ athlete: NewAthlete) {
    self._athlete = LazyReference(athlete)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _event = try values.decodeIfPresent(LazyReference<NewEvent>.self, forKey: .event) ?? LazyReference(identifiers: nil)
      _athlete = try values.decodeIfPresent(LazyReference<NewAthlete>.self, forKey: .athlete) ?? LazyReference(identifiers: nil)
      number = try values.decode(String.self, forKey: .number)
      name = try values.decode(String.self, forKey: .name)
      height = try values.decode(Double.self, forKey: .height)
      netScore = try values.decode(Double.self, forKey: .netScore)
      dd = try values.decode(Double.self, forKey: .dd)
      totalScore = try values.decode(Double.self, forKey: .totalScore)
      scores = try values.decodeIfPresent(List<JudgeScore>?.self, forKey: .scores) ?? .init()
      newathleteID = try values.decode(String.self, forKey: .newathleteID)
      neweventID = try values.decode(String.self, forKey: .neweventID)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_event, forKey: .event)
      try container.encode(_athlete, forKey: .athlete)
      try container.encode(number, forKey: .number)
      try container.encode(name, forKey: .name)
      try container.encode(height, forKey: .height)
      try container.encode(netScore, forKey: .netScore)
      try container.encode(dd, forKey: .dd)
      try container.encode(totalScore, forKey: .totalScore)
      try container.encode(scores, forKey: .scores)
      try container.encode(newathleteID, forKey: .newathleteID)
      try container.encode(neweventID, forKey: .neweventID)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}