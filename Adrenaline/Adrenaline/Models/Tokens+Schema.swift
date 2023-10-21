// swiftlint:disable all
import Amplify
import Foundation

extension Tokens {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case token
    case newuserID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let tokens = Tokens.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Tokens"
    model.syncPluralName = "Tokens"
    
    model.attributes(
      .index(fields: ["newuserID"], name: "byNewUser"),
      .primaryKey(fields: [tokens.id])
    )
    
    model.fields(
      .field(tokens.id, is: .required, ofType: .string),
      .field(tokens.token, is: .required, ofType: .string),
      .field(tokens.newuserID, is: .required, ofType: .string),
      .field(tokens.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(tokens.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Tokens: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}