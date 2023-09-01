// swiftlint:disable all
import Amplify
import Foundation

public struct Message: Model {
  public let id: String
  public var senderName: String
  public var body: String
  public var creationDate: Temporal.Date
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      senderName: String,
      body: String,
      creationDate: Temporal.Date) {
    self.init(id: id,
      senderName: senderName,
      body: body,
      creationDate: creationDate,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      senderName: String,
      body: String,
      creationDate: Temporal.Date,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.senderName = senderName
      self.body = body
      self.creationDate = creationDate
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}