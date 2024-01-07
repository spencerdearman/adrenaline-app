// swiftlint:disable all
import Amplify
import Foundation

extension MessageNewUser {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case isSender
    case newuserID
    case messageID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let messageNewUser = MessageNewUser.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "MessageNewUsers"
    model.syncPluralName = "MessageNewUsers"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .index(fields: ["messageID"], name: "byMessage"),
      .primaryKey(fields: [messageNewUser.id])
    )
    
    model.fields(
      .field(messageNewUser.id, is: .required, ofType: .string),
      .field(messageNewUser.isSender, is: .required, ofType: .bool),
      .field(messageNewUser.newuserID, is: .required, ofType: .string),
      .field(messageNewUser.messageID, is: .required, ofType: .string),
      .field(messageNewUser.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(messageNewUser.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<MessageNewUser> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension MessageNewUser: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == MessageNewUser {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var isSender: FieldPath<Bool>   {
      bool("isSender") 
    }
  public var newuserID: FieldPath<String>   {
      string("newuserID") 
    }
  public var messageID: FieldPath<String>   {
      string("messageID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}