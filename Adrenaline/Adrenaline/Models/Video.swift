// swiftlint:disable all
import Amplify
import Foundation

public struct Video: Model {
  public let id: String
  public var athlete: NewAthlete
  public var link: String
  public var title: String
  public var description: String?
  public var uploadDate: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      athlete: NewAthlete,
      link: String,
      title: String,
      description: String? = nil,
      uploadDate: Temporal.DateTime) {
    self.init(id: id,
      athlete: athlete,
      link: link,
      title: title,
      description: description,
      uploadDate: uploadDate,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      athlete: NewAthlete,
      link: String,
      title: String,
      description: String? = nil,
      uploadDate: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.athlete = athlete
      self.link = link
      self.title = title
      self.description = description
      self.uploadDate = uploadDate
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}