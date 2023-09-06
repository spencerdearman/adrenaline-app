// swiftlint:disable all
import Amplify
import Foundation

public struct ReceivedMessage: Model, Identifiable {
  public let id: String
  public var senderName: String
  public var body: String
  public var creationDate: Temporal.Date
  public var newuserID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      senderName: String,
      body: String,
      creationDate: Temporal.Date,
      newuserID: String) {
    self.init(id: id,
      senderName: senderName,
      body: body,
      creationDate: creationDate,
      newuserID: newuserID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      senderName: String,
      body: String,
      creationDate: Temporal.Date,
      newuserID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.senderName = senderName
      self.body = body
      self.creationDate = creationDate
      self.newuserID = newuserID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
