// swiftlint:disable all
import Amplify
import Foundation

public struct Tokens: Model {
  public let id: String
  public var token: String
  public var newuserID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      token: String,
      newuserID: String) {
    self.init(id: id,
      token: token,
      newuserID: newuserID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      token: String,
      newuserID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.token = token
      self.newuserID = newuserID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}