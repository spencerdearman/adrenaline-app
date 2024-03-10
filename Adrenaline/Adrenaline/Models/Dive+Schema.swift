// swiftlint:disable all
import Amplify
import Foundation

extension Dive {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case event
    case athlete
    case number
    case name
    case height
    case netScore
    case dd
    case totalScore
    case scores
    case newathleteID
    case neweventID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let dive = Dive.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Dives"
    model.syncPluralName = "Dives"
    
    model.attributes(
      .index(fields: ["newathleteID"], name: "byNewAthlete"),
      .index(fields: ["neweventID"], name: "byNewEvent"),
      .primaryKey(fields: [dive.id])
    )
    
    model.fields(
      .field(dive.id, is: .required, ofType: .string),
      .belongsTo(dive.event, is: .required, ofType: NewEvent.self, targetNames: ["newEventDivesId"]),
      .belongsTo(dive.athlete, is: .required, ofType: NewAthlete.self, targetNames: ["newAthleteDivesId"]),
      .field(dive.number, is: .required, ofType: .string),
      .field(dive.name, is: .required, ofType: .string),
      .field(dive.height, is: .required, ofType: .double),
      .field(dive.netScore, is: .required, ofType: .double),
      .field(dive.dd, is: .required, ofType: .double),
      .field(dive.totalScore, is: .required, ofType: .double),
      .hasMany(dive.scores, is: .optional, ofType: JudgeScore.self, associatedWith: JudgeScore.keys.diveID),
      .field(dive.newathleteID, is: .required, ofType: .string),
      .field(dive.neweventID, is: .required, ofType: .string),
      .field(dive.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(dive.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Dive> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Dive: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Dive {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var event: ModelPath<NewEvent>   {
      NewEvent.Path(name: "event", parent: self) 
    }
  public var athlete: ModelPath<NewAthlete>   {
      NewAthlete.Path(name: "athlete", parent: self) 
    }
  public var number: FieldPath<String>   {
      string("number") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var height: FieldPath<Double>   {
      double("height") 
    }
  public var netScore: FieldPath<Double>   {
      double("netScore") 
    }
  public var dd: FieldPath<Double>   {
      double("dd") 
    }
  public var totalScore: FieldPath<Double>   {
      double("totalScore") 
    }
  public var scores: ModelPath<JudgeScore>   {
      JudgeScore.Path(name: "scores", isCollection: true, parent: self) 
    }
  public var newathleteID: FieldPath<String>   {
      string("newathleteID") 
    }
  public var neweventID: FieldPath<String>   {
      string("neweventID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}