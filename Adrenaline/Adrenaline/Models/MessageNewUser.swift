// swiftlint:disable all
import Amplify
import Foundation

public struct MessageNewUser: Model {
  public let id: String
  public var isSender: Bool
  public var newuserID: String
  public var messageID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      isSender: Bool,
      newuserID: String,
      messageID: String) {
    self.init(id: id,
      isSender: isSender,
      newuserID: newuserID,
      messageID: messageID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      isSender: Bool,
      newuserID: String,
      messageID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.isSender = isSender
      self.newuserID = newuserID
      self.messageID = messageID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}