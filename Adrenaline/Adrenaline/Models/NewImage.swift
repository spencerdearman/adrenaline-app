// swiftlint:disable all
import Amplify
import Foundation

public struct NewImage: Model {
  public let id: String
  public var link: String
  public var uploadDate: Temporal.DateTime
  public var postID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      link: String,
      uploadDate: Temporal.DateTime,
      postID: String) {
    self.init(id: id,
      link: link,
      uploadDate: uploadDate,
      postID: postID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      link: String,
      uploadDate: Temporal.DateTime,
      postID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.link = link
      self.uploadDate = uploadDate
      self.postID = postID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}