// swiftlint:disable all
import Amplify
import Foundation

extension College {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case imageLink
    case athletes
    case coach
    case coachID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let college = College.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Colleges"
    model.syncPluralName = "Colleges"
    
    model.attributes(
      .primaryKey(fields: [college.id])
    )
    
    model.fields(
      .field(college.id, is: .required, ofType: .string),
      .field(college.name, is: .required, ofType: .string),
      .field(college.imageLink, is: .required, ofType: .string),
      .hasMany(college.athletes, is: .optional, ofType: NewAthlete.self, associatedWith: NewAthlete.keys.college),
      .hasOne(college.coach, is: .optional, ofType: CoachUser.self, associatedWith: CoachUser.keys.college, targetNames: ["coachID"]),
      .field(college.coachID, is: .optional, ofType: .string),
      .field(college.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(college.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<College> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension College: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == College {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var imageLink: FieldPath<String>   {
      string("imageLink") 
    }
  public var athletes: ModelPath<NewAthlete>   {
      NewAthlete.Path(name: "athletes", isCollection: true, parent: self) 
    }
  public var coach: ModelPath<CoachUser>   {
      CoachUser.Path(name: "coach", parent: self) 
    }
  public var coachID: FieldPath<String>   {
      string("coachID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}