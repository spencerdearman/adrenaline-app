// swiftlint:disable all
import Amplify
import Foundation

public struct NewAthlete: Model {
  public let id: String
  public var user: NewUser
  public var team: NewTeam?
  public var college: College?
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
  public var collegeID: String
  public var newteamID: String
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
      self.user = user
      self.team = team
      self.college = college
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
      self.collegeID = college == nil ? "": college!.id
      self.newteamID = team == nil ? "": team!.id
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
