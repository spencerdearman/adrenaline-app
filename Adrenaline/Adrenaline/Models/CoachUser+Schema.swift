// swiftlint:disable all
import Amplify
import Foundation

extension CoachUser {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case team
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
      .field(coachUser.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(coachUser.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension CoachUser: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
