// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model, Equatable {
  public let id: String
  public var caption: String?
  public var creationDate: Temporal.DateTime
  public var images: List<NewImage>?
  public var videos: List<Video>?
  public var newuserID: String
  public var usersSaving: List<UserSavedPost>?
  public var isCoachesOnly: Bool
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
    
  public static func == (lhs: Post, rhs: Post) -> Bool {
      lhs.id == rhs.id
  }
  
  public init(id: String = UUID().uuidString,
      caption: String? = nil,
      creationDate: Temporal.DateTime,
      images: List<NewImage>? = [],
      videos: List<Video>? = [],
      newuserID: String,
      usersSaving: List<UserSavedPost>? = [],
      isCoachesOnly: Bool) {
    self.init(id: id,
      caption: caption,
      creationDate: creationDate,
      images: images,
      videos: videos,
      newuserID: newuserID,
      usersSaving: usersSaving,
      isCoachesOnly: isCoachesOnly,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      caption: String? = nil,
      creationDate: Temporal.DateTime,
      images: List<NewImage>? = [],
      videos: List<Video>? = [],
      newuserID: String,
      usersSaving: List<UserSavedPost>? = [],
      isCoachesOnly: Bool,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.caption = caption
      self.creationDate = creationDate
      self.images = images
      self.videos = videos
      self.newuserID = newuserID
      self.usersSaving = usersSaving
      self.isCoachesOnly = isCoachesOnly
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
    
    // Not generated, added afterwards as a convenience init for creationDate
    public init(id: String = UUID().uuidString,
                            caption: String? = nil,
                            images: List<NewImage>? = [],
                            videos: List<Video>? = [],
                            newuserID: String,
                            isCoachesOnly: Bool) {
        self.init(id: id,
                  caption: caption,
                  creationDate: .now(),
                  images: images,
                  videos: videos,
                  newuserID: newuserID,
                  isCoachesOnly: isCoachesOnly,
                  createdAt: nil,
                  updatedAt: nil)
    }
}
