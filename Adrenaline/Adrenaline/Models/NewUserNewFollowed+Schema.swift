// swiftlint:disable all
import Amplify
import Foundation

extension NewUserNewFollowed {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case newUser
    case newFollowed
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newUserNewFollowed = NewUserNewFollowed.keys
    
    model.listPluralName = "NewUserNewFolloweds"
    model.syncPluralName = "NewUserNewFolloweds"
    
    model.attributes(
      .index(fields: ["newUserId"], name: "byNewUser"),
      .index(fields: ["newFollowedId"], name: "byNewFollowed"),
      .primaryKey(fields: [newUserNewFollowed.id])
    )
    
    model.fields(
      .field(newUserNewFollowed.id, is: .required, ofType: .string),
      .belongsTo(newUserNewFollowed.newUser, is: .required, ofType: NewUser.self, targetNames: ["newUserId"]),
      .belongsTo(newUserNewFollowed.newFollowed, is: .required, ofType: NewFollowed.self, targetNames: ["newFollowedId"]),
      .field(newUserNewFollowed.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newUserNewFollowed.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension NewUserNewFollowed: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}