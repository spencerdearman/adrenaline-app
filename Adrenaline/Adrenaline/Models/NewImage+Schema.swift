// swiftlint:disable all
import Amplify
import Foundation

extension NewImage {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case link
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
      .field(newImage.link, is: .required, ofType: .string),
      .field(newImage.uploadDate, is: .required, ofType: .dateTime),
      .field(newImage.postID, is: .required, ofType: .string),
      .field(newImage.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newImage.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension NewImage: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}