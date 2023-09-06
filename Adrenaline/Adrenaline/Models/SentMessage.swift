// swiftlint:disable all
import Amplify
import Foundation

public struct SentMessage: Model, Identifiable {
  public let id: String
  public var recipientName: String
  public var body: String
  public var creationDate: Temporal.Date
  public var SendReceivedMessage: ReceivedMessage
  public var newuserID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var sentMessageSendReceivedMessageId: String
  
  public init(id: String = UUID().uuidString,
      recipientName: String,
      body: String,
      creationDate: Temporal.Date,
      SendReceivedMessage: ReceivedMessage,
      newuserID: String,
      sentMessageSendReceivedMessageId: String) {
    self.init(id: id,
      recipientName: recipientName,
      body: body,
      creationDate: creationDate,
      SendReceivedMessage: SendReceivedMessage,
      newuserID: newuserID,
      createdAt: nil,
      updatedAt: nil,
      sentMessageSendReceivedMessageId: sentMessageSendReceivedMessageId)
  }
  internal init(id: String = UUID().uuidString,
      recipientName: String,
      body: String,
      creationDate: Temporal.Date,
      SendReceivedMessage: ReceivedMessage,
      newuserID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      sentMessageSendReceivedMessageId: String) {
      self.id = id
      self.recipientName = recipientName
      self.body = body
      self.creationDate = creationDate
      self.SendReceivedMessage = SendReceivedMessage
      self.newuserID = newuserID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.sentMessageSendReceivedMessageId = sentMessageSendReceivedMessageId
  }
}
