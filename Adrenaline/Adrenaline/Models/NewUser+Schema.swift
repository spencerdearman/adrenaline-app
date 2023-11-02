// swiftlint:disable all
import Amplify
import Foundation

extension NewUser {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case firstName
    case lastName
    case email
    case phone
    case diveMeetsID
    case accountType
    case athlete
    case coach
    case posts
    case tokens
    case savedPosts
    case favoritesIds
    case createdAt
    case updatedAt
    case newUserAthleteId
    case newUserCoachId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newUser = NewUser.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewUsers"
    model.syncPluralName = "NewUsers"
    
    model.attributes(
      .primaryKey(fields: [newUser.id])
    )
    
    model.fields(
      .field(newUser.id, is: .required, ofType: .string),
      .field(newUser.firstName, is: .required, ofType: .string),
      .field(newUser.lastName, is: .required, ofType: .string),
      .field(newUser.email, is: .required, ofType: .string),
      .field(newUser.phone, is: .optional, ofType: .string),
      .field(newUser.diveMeetsID, is: .optional, ofType: .string),
      .field(newUser.accountType, is: .required, ofType: .string),
      .hasOne(newUser.athlete, is: .optional, ofType: NewAthlete.self, associatedWith: NewAthlete.keys.user, targetNames: ["newUserAthleteId"]),
      .hasOne(newUser.coach, is: .optional, ofType: CoachUser.self, associatedWith: CoachUser.keys.user, targetNames: ["newUserCoachId"]),
      .hasMany(newUser.posts, is: .optional, ofType: Post.self, associatedWith: Post.keys.newuserID),
      .hasMany(newUser.tokens, is: .optional, ofType: Tokens.self, associatedWith: Tokens.keys.newuserID),
      .hasMany(newUser.savedPosts, is: .optional, ofType: UserSavedPost.self, associatedWith: UserSavedPost.keys.newuserID),
      .field(newUser.favoritesIds, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(newUser.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newUser.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newUser.newUserAthleteId, is: .optional, ofType: .string),
      .field(newUser.newUserCoachId, is: .optional, ofType: .string)
    )
    }
}

extension NewUser: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<NewUser>
}
