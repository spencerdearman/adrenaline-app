// swiftlint:disable all
import Amplify
import Foundation

public struct AcademicRecord: Model {
  public let id: String
  internal var _athlete: LazyReference<NewAthlete>
  public var athlete: NewAthlete   {
      get async throws { 
        try await _athlete.require()
      } 
    }
  public var satScore: Int?
  public var actScore: Int?
  public var weightedGPA: Double?
  public var gpaScale: Double?
  public var coursework: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      athlete: NewAthlete,
      satScore: Int? = nil,
      actScore: Int? = nil,
      weightedGPA: Double? = nil,
      gpaScale: Double? = nil,
      coursework: String? = nil) {
    self.init(id: id,
      athlete: athlete,
      satScore: satScore,
      actScore: actScore,
      weightedGPA: weightedGPA,
      gpaScale: gpaScale,
      coursework: coursework,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      athlete: NewAthlete,
      satScore: Int? = nil,
      actScore: Int? = nil,
      weightedGPA: Double? = nil,
      gpaScale: Double? = nil,
      coursework: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._athlete = LazyReference(athlete)
      self.satScore = satScore
      self.actScore = actScore
      self.weightedGPA = weightedGPA
      self.gpaScale = gpaScale
      self.coursework = coursework
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setAthlete(_ athlete: NewAthlete) {
    self._athlete = LazyReference(athlete)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      _athlete = try values.decodeIfPresent(LazyReference<NewAthlete>.self, forKey: .athlete) ?? LazyReference(identifiers: nil)
      satScore = try? values.decode(Int?.self, forKey: .satScore)
      actScore = try? values.decode(Int?.self, forKey: .actScore)
      weightedGPA = try? values.decode(Double?.self, forKey: .weightedGPA)
      gpaScale = try? values.decode(Double?.self, forKey: .gpaScale)
      coursework = try? values.decode(String?.self, forKey: .coursework)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_athlete, forKey: .athlete)
      try container.encode(satScore, forKey: .satScore)
      try container.encode(actScore, forKey: .actScore)
      try container.encode(weightedGPA, forKey: .weightedGPA)
      try container.encode(gpaScale, forKey: .gpaScale)
      try container.encode(coursework, forKey: .coursework)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}