// swiftlint:disable all
import Amplify
import Foundation

public struct NewFollowed: Model {
  public let id: String
  public var firstName: String
  public var lastName: String
  public var email: String?
  public var diveMeetsID: String?
  public var users: List<NewUserNewFollowed>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String? = nil,
      diveMeetsID: String? = nil,
      users: List<NewUserNewFollowed> = []) {
    self.init(id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      diveMeetsID: diveMeetsID,
      users: users,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String? = nil,
      diveMeetsID: String? = nil,
      users: List<NewUserNewFollowed> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.firstName = firstName
      self.lastName = lastName
      self.email = email
      self.diveMeetsID = diveMeetsID
      self.users = users
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}