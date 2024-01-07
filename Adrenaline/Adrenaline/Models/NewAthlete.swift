// swiftlint:disable all
import Amplify
import Foundation

public struct NewAthlete: Model {
  public let id: String
  internal var _user: LazyReference<NewUser>
  public var user: NewUser   {
      get async throws { 
        try await _user.require()
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
  public var heightFeet: Int
  public var heightInches: Int
  public var weight: Int
  public var weightUnit: String
  public var gender: String
  public var age: Int
  public var graduationYear: Int
  public var highSchool: String
  public var hometown: String
  public var springboardRating: Double?
  public var platformRating: Double?
  public var totalRating: Double?
  public var dives: List<Dive>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      user: NewUser,
      team: NewTeam? = nil,
      college: College? = nil,
      heightFeet: Int,
      heightInches: Int,
      weight: Int,
      weightUnit: String,
      gender: String,
      age: Int,
      graduationYear: Int,
      highSchool: String,
      hometown: String,
      springboardRating: Double? = nil,
      platformRating: Double? = nil,
      totalRating: Double? = nil,
      dives: List<Dive> = []) {
    self.init(id: id,
      user: user,
      team: team,
      college: college,
      heightFeet: heightFeet,
      heightInches: heightInches,
      weight: weight,
      weightUnit: weightUnit,
      gender: gender,
      age: age,
      graduationYear: graduationYear,
      highSchool: highSchool,
      hometown: hometown,
      springboardRating: springboardRating,
      platformRating: platformRating,
      totalRating: totalRating,
      dives: dives,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      user: NewUser,
      team: NewTeam? = nil,
      college: College? = nil,
      heightFeet: Int,
      heightInches: Int,
      weight: Int,
      weightUnit: String,
      gender: String,
      age: Int,
      graduationYear: Int,
      highSchool: String,
      hometown: String,
      springboardRating: Double? = nil,
      platformRating: Double? = nil,
      totalRating: Double? = nil,
      dives: List<Dive> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self._user = LazyReference(user)
      self._team = LazyReference(team)
      self._college = LazyReference(college)
      self.heightFeet = heightFeet
      self.heightInches = heightInches
      self.weight = weight
      self.weightUnit = weightUnit
      self.gender = gender
      self.age = age
      self.graduationYear = graduationYear
      self.highSchool = highSchool
      self.hometown = hometown
      self.springboardRating = springboardRating
      self.platformRating = platformRating
      self.totalRating = totalRating
      self.dives = dives
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setUser(_ user: NewUser) {
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
      heightFeet = try values.decode(Int.self, forKey: .heightFeet)
      heightInches = try values.decode(Int.self, forKey: .heightInches)
      weight = try values.decode(Int.self, forKey: .weight)
      weightUnit = try values.decode(String.self, forKey: .weightUnit)
      gender = try values.decode(String.self, forKey: .gender)
      age = try values.decode(Int.self, forKey: .age)
      graduationYear = try values.decode(Int.self, forKey: .graduationYear)
      highSchool = try values.decode(String.self, forKey: .highSchool)
      hometown = try values.decode(String.self, forKey: .hometown)
      springboardRating = try? values.decode(Double?.self, forKey: .springboardRating)
      platformRating = try? values.decode(Double?.self, forKey: .platformRating)
      totalRating = try? values.decode(Double?.self, forKey: .totalRating)
      dives = try values.decodeIfPresent(List<Dive>?.self, forKey: .dives) ?? .init()
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(_user, forKey: .user)
      try container.encode(_team, forKey: .team)
      try container.encode(_college, forKey: .college)
      try container.encode(heightFeet, forKey: .heightFeet)
      try container.encode(heightInches, forKey: .heightInches)
      try container.encode(weight, forKey: .weight)
      try container.encode(weightUnit, forKey: .weightUnit)
      try container.encode(gender, forKey: .gender)
      try container.encode(age, forKey: .age)
      try container.encode(graduationYear, forKey: .graduationYear)
      try container.encode(highSchool, forKey: .highSchool)
      try container.encode(hometown, forKey: .hometown)
      try container.encode(springboardRating, forKey: .springboardRating)
      try container.encode(platformRating, forKey: .platformRating)
      try container.encode(totalRating, forKey: .totalRating)
      try container.encode(dives, forKey: .dives)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}