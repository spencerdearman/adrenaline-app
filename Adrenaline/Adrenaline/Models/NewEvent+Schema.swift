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
    case newmeetID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newEvent = NewEvent.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewEvents"
    model.syncPluralName = "NewEvents"
    
    model.attributes(
      .index(fields: ["newmeetID"], name: "byNewMeet"),
      .primaryKey(fields: [newEvent.id])
    )
    
    model.fields(
      .field(newEvent.id, is: .required, ofType: .string),
      .belongsTo(newEvent.meet, is: .required, ofType: NewMeet.self, targetNames: ["newMeetEventsId"]),
      .field(newEvent.name, is: .required, ofType: .string),
      .field(newEvent.date, is: .required, ofType: .date),
      .field(newEvent.link, is: .required, ofType: .string),
      .field(newEvent.numEntries, is: .required, ofType: .int),
      .hasMany(newEvent.dives, is: .optional, ofType: Dive.self, associatedWith: Dive.keys.neweventID),
      .field(newEvent.newmeetID, is: .required, ofType: .string),
      .field(newEvent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newEvent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<NewEvent> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension NewEvent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == NewEvent {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var meet: ModelPath<NewMeet>   {
      NewMeet.Path(name: "meet", parent: self) 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var date: FieldPath<Temporal.Date>   {
      date("date") 
    }
  public var link: FieldPath<String>   {
      string("link") 
    }
  public var numEntries: FieldPath<Int>   {
      int("numEntries") 
    }
  public var dives: ModelPath<Dive>   {
      Dive.Path(name: "dives", isCollection: true, parent: self) 
    }
  public var newmeetID: FieldPath<String>   {
      string("newmeetID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}