// swiftlint:disable all
import Amplify
import Foundation

extension DiveMeetsDiver {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case firstName
    case lastName
    case gender
    case finaAge
    case hsGradYear
    case springboardRating
    case platformRating
    case totalRating
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let diveMeetsDiver = DiveMeetsDiver.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "DiveMeetsDivers"
    model.syncPluralName = "DiveMeetsDivers"
    
    model.attributes(
      .primaryKey(fields: [diveMeetsDiver.id])
    )
    
    model.fields(
      .field(diveMeetsDiver.id, is: .required, ofType: .string),
      .field(diveMeetsDiver.firstName, is: .required, ofType: .string),
      .field(diveMeetsDiver.lastName, is: .required, ofType: .string),
      .field(diveMeetsDiver.gender, is: .required, ofType: .string),
      .field(diveMeetsDiver.finaAge, is: .optional, ofType: .int),
      .field(diveMeetsDiver.hsGradYear, is: .optional, ofType: .int),
      .field(diveMeetsDiver.springboardRating, is: .optional, ofType: .double),
      .field(diveMeetsDiver.platformRating, is: .optional, ofType: .double),
      .field(diveMeetsDiver.totalRating, is: .optional, ofType: .double),
      .field(diveMeetsDiver.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(diveMeetsDiver.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<DiveMeetsDiver> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension DiveMeetsDiver: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == DiveMeetsDiver {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var firstName: FieldPath<String>   {
      string("firstName") 
    }
  public var lastName: FieldPath<String>   {
      string("lastName") 
    }
  public var gender: FieldPath<String>   {
      string("gender") 
    }
  public var finaAge: FieldPath<Int>   {
      int("finaAge") 
    }
  public var hsGradYear: FieldPath<Int>   {
      int("hsGradYear") 
    }
  public var springboardRating: FieldPath<Double>   {
      double("springboardRating") 
    }
  public var platformRating: FieldPath<Double>   {
      double("platformRating") 
    }
  public var totalRating: FieldPath<Double>   {
      double("totalRating") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}