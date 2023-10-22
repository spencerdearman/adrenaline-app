// swiftlint:disable all
import Amplify
import Foundation

public class NewUser: Model, Identifiable {
  public let id: String
  public var firstName: String
  public var lastName: String
  public var email: String
  public var phone: String?
  public var diveMeetsID: String?
  public var accountType: String
  public var athlete: NewAthlete?
  public var coach: CoachUser?
  public var followed: List<NewUserNewFollowed>?
  public var MessageNewUsers: List<MessageNewUser>?
  public var posts: List<Post>?
  public var tokens: List<Tokens>?
  public var savedPosts: List<UserSavedPost>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var newUserAthleteId: String?
  public var newUserCoachId: String?
  
  public convenience init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String,
      phone: String? = nil,
      diveMeetsID: String? = nil,
      accountType: String,
      athlete: NewAthlete? = nil,
      coach: CoachUser? = nil,
      followed: List<NewUserNewFollowed> = [],
      MessageNewUsers: List<MessageNewUser>? = [],
      posts: List<Post>? = [],
      tokens: List<Tokens>? = [],
      savedPosts: List<UserSavedPost>? = [],
      newUserAthleteId: String? = nil,
      newUserCoachId: String? = nil) {
    self.init(id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      diveMeetsID: diveMeetsID,
      accountType: accountType,
      athlete: athlete,
      coach: coach,
      followed: followed,
      MessageNewUsers: MessageNewUsers,
      posts: posts,
      tokens: tokens,
      savedPosts: savedPosts,
      createdAt: nil,
      updatedAt: nil,
      newUserAthleteId: newUserAthleteId,
      newUserCoachId: newUserCoachId)
  }
  internal init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String,
      phone: String? = nil,
      diveMeetsID: String? = nil,
      accountType: String,
      athlete: NewAthlete? = nil,
      coach: CoachUser? = nil,
      followed: List<NewUserNewFollowed> = [],
      MessageNewUsers: List<MessageNewUser>? = [],
      posts: List<Post>? = [],
      tokens: List<Tokens>? = [],
      savedPosts: List<UserSavedPost>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      newUserAthleteId: String? = nil,
      newUserCoachId: String? = nil) {
      self.id = id
      self.firstName = firstName
      self.lastName = lastName
      self.email = email
      self.phone = phone
      self.diveMeetsID = diveMeetsID
      self.accountType = accountType
      self.athlete = athlete
      self.coach = coach
      self.followed = followed
      self.MessageNewUsers = MessageNewUsers
      self.posts = posts
      self.tokens = tokens
      self.savedPosts = savedPosts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.newUserAthleteId = newUserAthleteId
      self.newUserCoachId = newUserCoachId
  }
}
