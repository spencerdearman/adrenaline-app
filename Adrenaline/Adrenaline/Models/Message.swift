// swiftlint:disable all
import Amplify
import Foundation

public struct Message: Model, Identifiable {
  public let id: String
  public var body: String
  public var creationDate: Temporal.Date
  public var MessageNewUsers: List<MessageNewUser>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      body: String,
      creationDate: Temporal.Date,
      MessageNewUsers: List<MessageNewUser>? = []) {
    self.init(id: id,
      body: body,
      creationDate: creationDate,
      MessageNewUsers: MessageNewUsers,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      body: String,
      creationDate: Temporal.Date,
      MessageNewUsers: List<MessageNewUser>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.body = body
      self.creationDate = creationDate
      self.MessageNewUsers = MessageNewUsers
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
