// swiftlint:disable all
import Amplify
import Foundation

extension NewFollowed {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case firstName
    case lastName
    case email
    case diveMeetsID
    case users
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newFollowed = NewFollowed.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewFolloweds"
    
    model.attributes(
      .primaryKey(fields: [newFollowed.id])
    )
    
    model.fields(
      .field(newFollowed.id, is: .required, ofType: .string),
      .field(newFollowed.firstName, is: .required, ofType: .string),
      .field(newFollowed.lastName, is: .required, ofType: .string),
      .field(newFollowed.email, is: .optional, ofType: .string),
      .field(newFollowed.diveMeetsID, is: .optional, ofType: .string),
      .hasMany(newFollowed.users, is: .optional, ofType: NewUserNewFollowed.self, associatedWith: NewUserNewFollowed.keys.newFollowed),
      .field(newFollowed.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newFollowed.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension NewFollowed: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
