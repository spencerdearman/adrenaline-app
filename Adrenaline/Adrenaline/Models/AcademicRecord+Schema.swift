// swiftlint:disable all
import Amplify
import Foundation

extension AcademicRecord {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case athlete
    case satScore
    case actScore
    case weightedGPA
    case gpaScale
    case coursework
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let academicRecord = AcademicRecord.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "AcademicRecords"
    model.syncPluralName = "AcademicRecords"
    
    model.attributes(
      .primaryKey(fields: [academicRecord.id])
    )
    
    model.fields(
      .field(academicRecord.id, is: .required, ofType: .string),
      .belongsTo(academicRecord.athlete, is: .required, ofType: NewAthlete.self, targetNames: ["academicRecordAthleteId"]),
      .field(academicRecord.satScore, is: .optional, ofType: .int),
      .field(academicRecord.actScore, is: .optional, ofType: .int),
      .field(academicRecord.weightedGPA, is: .optional, ofType: .double),
      .field(academicRecord.gpaScale, is: .optional, ofType: .double),
      .field(academicRecord.coursework, is: .optional, ofType: .string),
      .field(academicRecord.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(academicRecord.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<AcademicRecord> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension AcademicRecord: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == AcademicRecord {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var athlete: ModelPath<NewAthlete>   {
      NewAthlete.Path(name: "athlete", parent: self) 
    }
  public var satScore: FieldPath<Int>   {
      int("satScore") 
    }
  public var actScore: FieldPath<Int>   {
      int("actScore") 
    }
  public var weightedGPA: FieldPath<Double>   {
      double("weightedGPA") 
    }
  public var gpaScale: FieldPath<Double>   {
      double("gpaScale") 
    }
  public var coursework: FieldPath<String>   {
      string("coursework") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}