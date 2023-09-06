// swiftlint:disable all
import Amplify
import Foundation

extension ReceivedMessage {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case senderName
    case body
    case creationDate
    case newuserID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let receivedMessage = ReceivedMessage.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "ReceivedMessages"
    model.syncPluralName = "ReceivedMessages"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .primaryKey(fields: [receivedMessage.id])
    )
    
    model.fields(
      .field(receivedMessage.id, is: .required, ofType: .string),
      .field(receivedMessage.senderName, is: .required, ofType: .string),
      .field(receivedMessage.body, is: .required, ofType: .string),
      .field(receivedMessage.creationDate, is: .required, ofType: .date),
      .field(receivedMessage.newuserID, is: .required, ofType: .string),
      .field(receivedMessage.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(receivedMessage.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ReceivedMessage: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}