// swiftlint:disable all
import Amplify
import Foundation

extension NewMeet {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case meetID
    case name
    case organization
    case startDate
    case endDate
    case city
    case state
    case country
    case link
    case meetType
    case events
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newMeet = NewMeet.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewMeets"
    model.syncPluralName = "NewMeets"
    
    model.attributes(
      .primaryKey(fields: [newMeet.id])
    )
    
    model.fields(
      .field(newMeet.id, is: .required, ofType: .string),
      .field(newMeet.meetID, is: .required, ofType: .int),
      .field(newMeet.name, is: .required, ofType: .string),
      .field(newMeet.organization, is: .optional, ofType: .string),
      .field(newMeet.startDate, is: .required, ofType: .date),
      .field(newMeet.endDate, is: .required, ofType: .date),
      .field(newMeet.city, is: .required, ofType: .string),
      .field(newMeet.state, is: .required, ofType: .string),
      .field(newMeet.country, is: .required, ofType: .string),
      .field(newMeet.link, is: .required, ofType: .string),
      .field(newMeet.meetType, is: .required, ofType: .int),
      .hasMany(newMeet.events, is: .optional, ofType: NewEvent.self, associatedWith: NewEvent.keys.newmeetID),
      .field(newMeet.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newMeet.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<NewMeet> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension NewMeet: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == NewMeet {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var meetID: FieldPath<Int>   {
      int("meetID") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var organization: FieldPath<String>   {
      string("organization") 
    }
  public var startDate: FieldPath<Temporal.Date>   {
      date("startDate") 
    }
  public var endDate: FieldPath<Temporal.Date>   {
      date("endDate") 
    }
  public var city: FieldPath<String>   {
      string("city") 
    }
  public var state: FieldPath<String>   {
      string("state") 
    }
  public var country: FieldPath<String>   {
      string("country") 
    }
  public var link: FieldPath<String>   {
      string("link") 
    }
  public var meetType: FieldPath<Int>   {
      int("meetType") 
    }
  public var events: ModelPath<NewEvent>   {
      NewEvent.Path(name: "events", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}