// swiftlint:disable all
import Amplify
import Foundation

extension NewEvent {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case meet
    case name
    case date
    case link
    case numEntries
    case dives
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newEvent = NewEvent.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewEvents"
    
    model.attributes(
      .primaryKey(fields: [newEvent.id])
    )
    
    model.fields(
      .field(newEvent.id, is: .required, ofType: .string),
      .belongsTo(newEvent.meet, is: .required, ofType: NewMeet.self, targetNames: ["newMeetEventsId"]),
      .field(newEvent.name, is: .required, ofType: .string),
      .field(newEvent.date, is: .required, ofType: .date),
      .field(newEvent.link, is: .required, ofType: .string),
      .field(newEvent.numEntries, is: .required, ofType: .int),
      .hasMany(newEvent.dives, is: .optional, ofType: Dive.self, associatedWith: Dive.keys.event),
      .field(newEvent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newEvent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension NewEvent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
