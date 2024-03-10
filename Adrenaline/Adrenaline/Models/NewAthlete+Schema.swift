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
    case academics
    case heightFeet
    case heightInches
    case weight
    case weightUnit
    case gender
    case age
    case dateOfBirth
    case graduationYear
    case highSchool
    case hometown
    case springboardRating
    case platformRating
    case totalRating
    case dives
    case createdAt
    case updatedAt
    case newAthleteAcademicsId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newAthlete = NewAthlete.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
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
      .belongsTo(newAthlete.team, is: .optional, ofType: NewTeam.self, targetNames: ["newteamID"]),
      .belongsTo(newAthlete.college, is: .optional, ofType: College.self, targetNames: ["collegeID"]),
      .hasOne(newAthlete.academics, is: .optional, ofType: AcademicRecord.self, associatedWith: AcademicRecord.keys.athlete, targetNames: ["newAthleteAcademicsId"]),
      .field(newAthlete.heightFeet, is: .required, ofType: .int),
      .field(newAthlete.heightInches, is: .required, ofType: .int),
      .field(newAthlete.weight, is: .required, ofType: .int),
      .field(newAthlete.weightUnit, is: .required, ofType: .string),
      .field(newAthlete.gender, is: .required, ofType: .string),
      .field(newAthlete.age, is: .required, ofType: .int),
      .field(newAthlete.dateOfBirth, is: .required, ofType: .date),
      .field(newAthlete.graduationYear, is: .required, ofType: .int),
      .field(newAthlete.highSchool, is: .required, ofType: .string),
      .field(newAthlete.hometown, is: .required, ofType: .string),
      .field(newAthlete.springboardRating, is: .optional, ofType: .double),
      .field(newAthlete.platformRating, is: .optional, ofType: .double),
      .field(newAthlete.totalRating, is: .optional, ofType: .double),
      .hasMany(newAthlete.dives, is: .optional, ofType: Dive.self, associatedWith: Dive.keys.newathleteID),
      .field(newAthlete.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newAthlete.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newAthlete.newAthleteAcademicsId, is: .optional, ofType: .string)
    )
    }
    public class Path: ModelPath<NewAthlete> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension NewAthlete: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == NewAthlete {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var user: ModelPath<NewUser>   {
      NewUser.Path(name: "user", parent: self) 
    }
  public var team: ModelPath<NewTeam>   {
      NewTeam.Path(name: "team", parent: self) 
    }
  public var college: ModelPath<College>   {
      College.Path(name: "college", parent: self) 
    }
  public var academics: ModelPath<AcademicRecord>   {
      AcademicRecord.Path(name: "academics", parent: self) 
    }
  public var heightFeet: FieldPath<Int>   {
      int("heightFeet") 
    }
  public var heightInches: FieldPath<Int>   {
      int("heightInches") 
    }
  public var weight: FieldPath<Int>   {
      int("weight") 
    }
  public var weightUnit: FieldPath<String>   {
      string("weightUnit") 
    }
  public var gender: FieldPath<String>   {
      string("gender") 
    }
  public var age: FieldPath<Int>   {
      int("age") 
    }
  public var dateOfBirth: FieldPath<Temporal.Date>   {
      date("dateOfBirth") 
    }
  public var graduationYear: FieldPath<Int>   {
      int("graduationYear") 
    }
  public var highSchool: FieldPath<String>   {
      string("highSchool") 
    }
  public var hometown: FieldPath<String>   {
      string("hometown") 
    }
  public var springboardRating: FieldPath<Double>   {
      double("springboardRating") 
    }
  public var platformRating: FieldPath<Double>   {
      double("platformRating") 
    }
  public var totalRating: FieldPath<Double>   {
      double("totalRating") 
    }
  public var dives: ModelPath<Dive>   {
      Dive.Path(name: "dives", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
  public var newAthleteAcademicsId: FieldPath<String>   {
      string("newAthleteAcademicsId") 
    }
}