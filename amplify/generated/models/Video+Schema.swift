// swiftlint:disable all
import Amplify
import Foundation

extension Video {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case athlete
    case link
    case title
    case description
    case uploadDate
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let video = Video.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Videos"
    
    model.attributes(
      .primaryKey(fields: [video.id])
    )
    
    model.fields(
      .field(video.id, is: .required, ofType: .string),
      .belongsTo(video.athlete, is: .required, ofType: NewAthlete.self, targetNames: ["newAthleteVideosId"]),
      .field(video.link, is: .required, ofType: .string),
      .field(video.title, is: .required, ofType: .string),
      .field(video.description, is: .optional, ofType: .string),
      .field(video.uploadDate, is: .required, ofType: .dateTime),
      .field(video.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(video.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Video: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
