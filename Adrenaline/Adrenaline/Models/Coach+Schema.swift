// swiftlint:disable all
import Amplify
import Foundation

extension Coach {
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
    let coach = Coach.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Coaches"
    
    model.attributes(
      .primaryKey(fields: [coach.id])
    )
    
    model.fields(
      .field(coach.id, is: .required, ofType: .string),
      .belongsTo(coach.user, is: .optional, ofType: NewUser.self, targetNames: ["coachUserId"]),
      .belongsTo(coach.team, is: .optional, ofType: NewTeam.self, targetNames: ["coachTeamId"]),
      .field(coach.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(coach.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Coach: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
    public typealias IdentifierProtocol = DefaultModelIdentifier<Coach>
}
