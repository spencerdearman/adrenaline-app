// swiftlint:disable all
import Amplify
import Foundation

extension College {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case imageLink
    case athletes
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let college = College.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Colleges"
    model.syncPluralName = "Colleges"
    
    model.attributes(
      .primaryKey(fields: [college.id])
    )
    
    model.fields(
      .field(college.id, is: .required, ofType: .string),
      .field(college.name, is: .required, ofType: .string),
      .field(college.imageLink, is: .required, ofType: .string),
      .hasMany(college.athletes, is: .optional, ofType: NewAthlete.self, associatedWith: NewAthlete.keys.collegeID),
      .field(college.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(college.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension College: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}