// swiftlint:disable all
import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case caption
    case creationDate
    case images
    case videos
    case newuserID
    case usersSaving
    case isCoachesOnly
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
      .field(post.caption, is: .optional, ofType: .string),
      .field(post.creationDate, is: .required, ofType: .dateTime),
      .hasMany(post.images, is: .optional, ofType: NewImage.self, associatedWith: NewImage.keys.postID),
      .hasMany(post.videos, is: .optional, ofType: Video.self, associatedWith: Video.keys.postID),
      .field(post.newuserID, is: .required, ofType: .string),
      .hasMany(post.usersSaving, is: .optional, ofType: UserSavedPost.self, associatedWith: UserSavedPost.keys.postID),
      .field(post.isCoachesOnly, is: .required, ofType: .bool),
      .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Post {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var caption: FieldPath<String>   {
      string("caption") 
    }
  public var creationDate: FieldPath<Temporal.DateTime>   {
      datetime("creationDate") 
    }
  public var images: ModelPath<NewImage>   {
      NewImage.Path(name: "images", isCollection: true, parent: self) 
    }
  public var videos: ModelPath<Video>   {
      Video.Path(name: "videos", isCollection: true, parent: self) 
    }
  public var newuserID: FieldPath<String>   {
      string("newuserID") 
    }
  public var usersSaving: ModelPath<UserSavedPost>   {
      UserSavedPost.Path(name: "usersSaving", isCollection: true, parent: self) 
    }
  public var isCoachesOnly: FieldPath<Bool>   {
      bool("isCoachesOnly") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}