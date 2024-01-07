// swiftlint:disable all
import Amplify
import Foundation

extension NewImage {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case s3key
    case uploadDate
    case postID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newImage = NewImage.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewImages"
    model.syncPluralName = "NewImages"
    
    model.attributes(
      .index(fields: ["postID"], name: "byPost"),
      .primaryKey(fields: [newImage.id])
    )
    
    model.fields(
      .field(newImage.id, is: .required, ofType: .string),
      .field(newImage.s3key, is: .required, ofType: .string),
      .field(newImage.uploadDate, is: .required, ofType: .dateTime),
      .field(newImage.postID, is: .required, ofType: .string),
      .field(newImage.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newImage.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<NewImage> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension NewImage: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == NewImage {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var s3key: FieldPath<String>   {
      string("s3key") 
    }
  public var uploadDate: FieldPath<Temporal.DateTime>   {
      datetime("uploadDate") 
    }
  public var postID: FieldPath<String>   {
      string("postID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}