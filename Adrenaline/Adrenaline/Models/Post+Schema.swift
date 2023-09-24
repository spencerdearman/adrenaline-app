// swiftlint:disable all
import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case description
    case creationDate
    case images
    case videos
    case newuserID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post = Post.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Posts"
    model.syncPluralName = "Posts"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .primaryKey(fields: [post.id])
    )
    
    model.fields(
      .field(post.id, is: .required, ofType: .string),
      .field(post.title, is: .optional, ofType: .string),
      .field(post.description, is: .optional, ofType: .string),
      .field(post.creationDate, is: .required, ofType: .dateTime),
      .hasMany(post.images, is: .optional, ofType: NewImage.self, associatedWith: NewImage.keys.postID),
      .hasMany(post.videos, is: .optional, ofType: Video.self, associatedWith: Video.keys.postID),
      .field(post.newuserID, is: .required, ofType: .string),
      .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}