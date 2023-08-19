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
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let dive = Dive.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Dives"
    model.syncPluralName = "Dives"
    
    model.attributes(
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
      .hasMany(dive.scores, is: .optional, ofType: JudgeScore.self, associatedWith: JudgeScore.keys.dive),
      .field(dive.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(dive.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Dive: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}