// swiftlint:disable all
import Amplify
import Foundation

extension JudgeScore {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case dive
    case score
    case diveID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let judgeScore = JudgeScore.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "JudgeScores"
    model.syncPluralName = "JudgeScores"
    
    model.attributes(
      .index(fields: ["diveID"], name: "byDive"),
      .primaryKey(fields: [judgeScore.id])
    )
    
    model.fields(
      .field(judgeScore.id, is: .required, ofType: .string),
      .belongsTo(judgeScore.dive, is: .required, ofType: Dive.self, targetNames: ["diveScoresId"]),
      .field(judgeScore.score, is: .required, ofType: .double),
      .field(judgeScore.diveID, is: .required, ofType: .string),
      .field(judgeScore.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(judgeScore.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<JudgeScore> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension JudgeScore: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == JudgeScore {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var dive: ModelPath<Dive>   {
      Dive.Path(name: "dive", parent: self) 
    }
  public var score: FieldPath<Double>   {
      double("score") 
    }
  public var diveID: FieldPath<String>   {
      string("diveID") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}