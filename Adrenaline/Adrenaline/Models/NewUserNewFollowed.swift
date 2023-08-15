// swiftlint:disable all
import Amplify
import Foundation

public struct NewUserNewFollowed: Model {
  public let id: String
  public var newUser: NewUser
  public var newFollowed: NewFollowed
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      newUser: NewUser,
      newFollowed: NewFollowed) {
    self.init(id: id,
      newUser: newUser,
      newFollowed: newFollowed,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      newUser: NewUser,
      newFollowed: NewFollowed,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.newUser = newUser
      self.newFollowed = newFollowed
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
