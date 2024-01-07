// swiftlint:disable all
import Amplify
import Foundation

public struct JudgeScore: Model {
  public let id: String
  internal var _dive: LazyReference<Dive>
  public var dive: Dive   {
      get async throws { 
        try await _dive.require()
      } 
    }
  public var score: Double
  public var diveID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      dive: Dive,
      score: Double,
      diveID: String) {
    self.init(id: id,
      dive: dive,
      score: score,
      diveID: diveID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      dive: Dive,
      score: Double,
      diveID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._dive = LazyReference(dive)
      self.score = score
      self.diveID = diveID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setDive(_ dive: Dive) {
    self._dive = LazyReference(dive)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _dive = try values.decodeIfPresent(LazyReference<Dive>.self, forKey: .dive) ?? LazyReference(identifiers: nil)
      score = try values.decode(Double.self, forKey: .score)
      diveID = try values.decode(String.self, forKey: .diveID)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_dive, forKey: .dive)
      try container.encode(score, forKey: .score)
      try container.encode(diveID, forKey: .diveID)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}