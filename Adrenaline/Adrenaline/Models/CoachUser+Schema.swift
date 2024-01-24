// swiftlint:disable all
import Amplify
import Foundation

extension CoachUser {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case team
    case college
    case favoritesOrder
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let coachUser = CoachUser.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "CoachUsers"
    model.syncPluralName = "CoachUsers"
    
    model.attributes(
      .primaryKey(fields: [coachUser.id])
    )
    
    model.fields(
      .field(coachUser.id, is: .required, ofType: .string),
      .belongsTo(coachUser.user, is: .optional, ofType: NewUser.self, targetNames: ["coachUserUserId"]),
      .belongsTo(coachUser.team, is: .optional, ofType: NewTeam.self, targetNames: ["coachUserTeamId"]),
      .belongsTo(coachUser.college, is: .optional, ofType: College.self, targetNames: ["coachUserCollegeId"]),
      .field(coachUser.favoritesOrder, is: .required, ofType: .embeddedCollection(of: Int.self)),
      .field(coachUser.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(coachUser.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<CoachUser> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension CoachUser: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == CoachUser {
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
  public var favoritesOrder: FieldPath<Int>   {
      int("favoritesOrder") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}