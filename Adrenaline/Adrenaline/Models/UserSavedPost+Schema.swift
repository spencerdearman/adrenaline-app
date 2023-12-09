// swiftlint:disable all
import Amplify
import Foundation

extension UserSavedPost {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case newuserID
    case postID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userSavedPost = UserSavedPost.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "UserSavedPosts"
    model.syncPluralName = "UserSavedPosts"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .index(fields: ["postID"], name: "byPost"),
      .primaryKey(fields: [userSavedPost.id])
    )
    
    model.fields(
      .field(userSavedPost.id, is: .required, ofType: .string),
      .field(userSavedPost.newuserID, is: .required, ofType: .string),
      .field(userSavedPost.postID, is: .required, ofType: .string),
      .field(userSavedPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userSavedPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserSavedPost: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}