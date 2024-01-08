// swiftlint:disable all
import Amplify
import Foundation

public struct NewUser: Model {
  public let id: String
  public var firstName: String
  public var lastName: String
  public var email: String
  public var phone: String?
  public var diveMeetsID: String?
  public var accountType: String
  internal var _athlete: LazyReference<NewAthlete>
  public var athlete: NewAthlete?   {
      get async throws { 
        try await _athlete.get()
      } 
    }
  internal var _coach: LazyReference<CoachUser>
  public var coach: CoachUser?   {
      get async throws { 
        try await _coach.get()
      } 
    }
  public var posts: List<Post>?
  public var tokens: [String]
  public var savedPosts: List<UserSavedPost>?
  public var favoritesIds: [String]
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var newUserAthleteId: String?
  public var newUserCoachId: String?
  
  public init(id: String = UUID().uuidString,
      firstName: String,
      lastName: String,
      email: String,
      phone: String? = nil,
      diveMeetsID: String? = nil,
      accountType: String,
      athlete: NewAthlete? = nil,
      coach: CoachUser? = nil,
      posts: List<Post>? = [],
      tokens: [String] = [],
      savedPosts: List<UserSavedPost>? = [],
      favoritesIds: [String] = [],
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
      posts: posts,
      tokens: tokens,
      savedPosts: savedPosts,
      favoritesIds: favoritesIds,
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
      posts: List<Post>? = [],
      tokens: [String] = [],
      savedPosts: List<UserSavedPost>? = [],
      favoritesIds: [String] = [],
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
      self._athlete = LazyReference(athlete)
      self._coach = LazyReference(coach)
      self.posts = posts
      self.tokens = tokens
      self.savedPosts = savedPosts
      self.favoritesIds = favoritesIds
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.newUserAthleteId = newUserAthleteId
      self.newUserCoachId = newUserCoachId
  }
  public mutating func setAthlete(_ athlete: NewAthlete? = nil) {
    self._athlete = LazyReference(athlete)
  }
  public mutating func setCoach(_ coach: CoachUser? = nil) {
    self._coach = LazyReference(coach)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      firstName = try values.decode(String.self, forKey: .firstName)
      lastName = try values.decode(String.self, forKey: .lastName)
      email = try values.decode(String.self, forKey: .email)
      phone = try? values.decode(String?.self, forKey: .phone)
      diveMeetsID = try? values.decode(String?.self, forKey: .diveMeetsID)
      accountType = try values.decode(String.self, forKey: .accountType)
      _athlete = try values.decodeIfPresent(LazyReference<NewAthlete>.self, forKey: .athlete) ?? LazyReference(identifiers: nil)
      _coach = try values.decodeIfPresent(LazyReference<CoachUser>.self, forKey: .coach) ?? LazyReference(identifiers: nil)
      posts = try values.decodeIfPresent(List<Post>?.self, forKey: .posts) ?? .init()
      tokens = try values.decode([String].self, forKey: .tokens)
      savedPosts = try values.decodeIfPresent(List<UserSavedPost>?.self, forKey: .savedPosts) ?? .init()
      favoritesIds = try values.decode([String].self, forKey: .favoritesIds)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
      newUserAthleteId = try? values.decode(String?.self, forKey: .newUserAthleteId)
      newUserCoachId = try? values.decode(String?.self, forKey: .newUserCoachId)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(firstName, forKey: .firstName)
      try container.encode(lastName, forKey: .lastName)
      try container.encode(email, forKey: .email)
      try container.encode(phone, forKey: .phone)
      try container.encode(diveMeetsID, forKey: .diveMeetsID)
      try container.encode(accountType, forKey: .accountType)
      try container.encode(_athlete, forKey: .athlete)
      try container.encode(_coach, forKey: .coach)
      try container.encode(posts, forKey: .posts)
      try container.encode(tokens, forKey: .tokens)
      try container.encode(savedPosts, forKey: .savedPosts)
      try container.encode(favoritesIds, forKey: .favoritesIds)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(newUserAthleteId, forKey: .newUserAthleteId)
      try container.encode(newUserCoachId, forKey: .newUserCoachId)
  }
}