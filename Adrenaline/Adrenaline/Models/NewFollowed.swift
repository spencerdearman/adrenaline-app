// swiftlint:disable all
import Amplify
import Foundation

public class NewFollowed: Model {
  public let id: String
  public var email: String
  public var users: List<NewUserNewFollowed>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
    public convenience init(id: String = UUID().uuidString,
      email: String,
      users: List<NewUserNewFollowed> = []) {
    self.init(id: id,
      email: email,
      users: users,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      email: String,
      users: List<NewUserNewFollowed> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.email = email
      self.users = users
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
