// swiftlint:disable all
import Amplify
import Foundation

extension TeamJoinRequest {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case team
    case status
    case createdAt
    case updatedAt
    case teamJoinRequestUserId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let teamJoinRequest = TeamJoinRequest.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "TeamJoinRequests"
    model.syncPluralName = "TeamJoinRequests"
    
    model.attributes(
      .primaryKey(fields: [teamJoinRequest.id])
    )
    
    model.fields(
      .field(teamJoinRequest.id, is: .required, ofType: .string),
      .hasOne(teamJoinRequest.user, is: .required, ofType: NewUser.self, associatedWith: NewUser.keys.id, targetNames: ["teamJoinRequestUserId"]),
      .belongsTo(teamJoinRequest.team, is: .required, ofType: NewTeam.self, targetNames: ["newTeamJoinRequestsId"]),
      .field(teamJoinRequest.status, is: .required, ofType: .enum(type: TeamJoinRequestStatus.self)),
      .field(teamJoinRequest.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(teamJoinRequest.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(teamJoinRequest.teamJoinRequestUserId, is: .required, ofType: .string)
    )
    }
    public class Path: ModelPath<TeamJoinRequest> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension TeamJoinRequest: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == TeamJoinRequest {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var user: ModelPath<NewUser>   {
      NewUser.Path(name: "user", parent: self) 
    }
  public var team: ModelPath<NewTeam>   {
      NewTeam.Path(name: "team", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
  public var teamJoinRequestUserId: FieldPath<String>   {
      string("teamJoinRequestUserId") 
    }
}