// swiftlint:disable all
import Amplify
import Foundation

public struct UserSavedPost: Model {
  public let id: String
  public var newuserID: String
  public var postID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      newuserID: String,
      postID: String) {
    self.init(id: id,
      newuserID: newuserID,
      postID: postID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      newuserID: String,
      postID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.newuserID = newuserID
      self.postID = postID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}