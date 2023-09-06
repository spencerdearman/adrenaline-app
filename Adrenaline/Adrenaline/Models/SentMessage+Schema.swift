// swiftlint:disable all
import Amplify
import Foundation

extension SentMessage {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case recipientName
    case body
    case creationDate
    case SendReceivedMessage
    case newuserID
    case createdAt
    case updatedAt
    case sentMessageSendReceivedMessageId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let sentMessage = SentMessage.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "SentMessages"
    model.syncPluralName = "SentMessages"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .primaryKey(fields: [sentMessage.id])
    )
    
    model.fields(
      .field(sentMessage.id, is: .required, ofType: .string),
      .field(sentMessage.recipientName, is: .required, ofType: .string),
      .field(sentMessage.body, is: .required, ofType: .string),
      .field(sentMessage.creationDate, is: .required, ofType: .date),
      .hasOne(sentMessage.SendReceivedMessage, is: .required, ofType: ReceivedMessage.self, associatedWith: ReceivedMessage.keys.id, targetNames: ["sentMessageSendReceivedMessageId"]),
      .field(sentMessage.newuserID, is: .required, ofType: .string),
      .field(sentMessage.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(sentMessage.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(sentMessage.sentMessageSendReceivedMessageId, is: .required, ofType: .string)
    )
    }
}

extension SentMessage: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}