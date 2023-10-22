// swiftlint:disable all
import Amplify
import Foundation

extension NewAthlete {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case team
    case college
    case heightFeet
    case heightInches
    case weight
    case weightUnit
    case gender
    case age
    case graduationYear
    case highSchool
    case hometown
    case springboardRating
    case platformRating
    case totalRating
    case dives
    case collegeID
    case newteamID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newAthlete = NewAthlete.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewAthletes"
    model.syncPluralName = "NewAthletes"
    
    model.attributes(
      .index(fields: ["collegeID"], name: "byCollege"),
      .index(fields: ["newteamID"], name: "byNewTeam"),
      .primaryKey(fields: [newAthlete.id])
    )
    
    model.fields(
      .field(newAthlete.id, is: .required, ofType: .string),
      .belongsTo(newAthlete.user, is: .required, ofType: NewUser.self, targetNames: ["newAthleteUserId"]),
      .belongsTo(newAthlete.team, is: .optional, ofType: NewTeam.self, targetNames: ["newTeamAthletesId"]),
      .belongsTo(newAthlete.college, is: .optional, ofType: College.self, targetNames: ["collegeAthletesId"]),
      .field(newAthlete.heightFeet, is: .required, ofType: .int),
      .field(newAthlete.heightInches, is: .required, ofType: .int),
      .field(newAthlete.weight, is: .required, ofType: .int),
      .field(newAthlete.weightUnit, is: .required, ofType: .string),
      .field(newAthlete.gender, is: .required, ofType: .string),
      .field(newAthlete.age, is: .required, ofType: .int),
      .field(newAthlete.graduationYear, is: .required, ofType: .int),
      .field(newAthlete.highSchool, is: .required, ofType: .string),
      .field(newAthlete.hometown, is: .required, ofType: .string),
      .field(newAthlete.springboardRating, is: .optional, ofType: .double),
      .field(newAthlete.platformRating, is: .optional, ofType: .double),
      .field(newAthlete.totalRating, is: .optional, ofType: .double),
      .hasMany(newAthlete.dives, is: .optional, ofType: Dive.self, associatedWith: Dive.keys.newathleteID),
      .field(newAthlete.collegeID, is: .optional, ofType: .string),
      .field(newAthlete.newteamID, is: .optional, ofType: .string),
      .field(newAthlete.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newAthlete.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension NewAthlete: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}