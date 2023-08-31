// swiftlint:disable all
import Amplify
import Foundation

public struct College: Model {
  public let id: String
  public var name: String
  public var imageLink: String
  public var athletes: List<NewAthlete>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      imageLink: String,
      athletes: List<NewAthlete>? = nil) {
    self.init(id: id,
      name: name,
      imageLink: imageLink,
      athletes: athletes,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      imageLink: String,
      athletes: List<NewAthlete>? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.imageLink = imageLink
      self.athletes = athletes
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
