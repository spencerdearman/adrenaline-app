// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String?
  public var description: String?
  public var creationDate: Temporal.DateTime
  public var images: List<NewImage>?
  public var videos: List<Video>?
  public var newuserID: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String? = nil,
      description: String? = nil,
      creationDate: Temporal.DateTime,
      images: List<NewImage>? = [],
      videos: List<Video>? = [],
      newuserID: String) {
    self.init(id: id,
      title: title,
      description: description,
      creationDate: creationDate,
      images: images,
      videos: videos,
      newuserID: newuserID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String? = nil,
      description: String? = nil,
      creationDate: Temporal.DateTime,
      images: List<NewImage>? = [],
      videos: List<Video>? = [],
      newuserID: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.description = description
      self.creationDate = creationDate
      self.images = images
      self.videos = videos
      self.newuserID = newuserID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
    
    // Not generated, added afterwards as a convenience init for creationDate
    public init(id: String = UUID().uuidString,
                            title: String? = nil,
                            description: String? = nil,
                            images: List<NewImage>? = [],
                            videos: List<Video>? = [],
                            newuserID: String) {
        self.init(id: id,
                  title: title,
                  description: description,
                  creationDate: .now(),
                  images: images,
                  videos: videos,
                  newuserID: newuserID,
                  createdAt: nil,
                  updatedAt: nil)
    }
}
