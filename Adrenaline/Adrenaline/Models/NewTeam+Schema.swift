// swiftlint:disable all
import Amplify
import Foundation

extension NewTeam {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case coach
    case athletes
    case createdAt
    case updatedAt
    case newTeamCoachId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let newTeam = NewTeam.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "NewTeams"
    model.syncPluralName = "NewTeams"
    
    model.attributes(
      .primaryKey(fields: [newTeam.id])
    )
    
    model.fields(
      .field(newTeam.id, is: .required, ofType: .string),
      .field(newTeam.name, is: .required, ofType: .string),
      .hasOne(newTeam.coach, is: .optional, ofType: CoachUser.self, associatedWith: CoachUser.keys.team, targetNames: ["newTeamCoachId"]),
      .hasMany(newTeam.athletes, is: .optional, ofType: NewAthlete.self, associatedWith: NewAthlete.keys.team),
      .field(newTeam.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newTeam.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(newTeam.newTeamCoachId, is: .optional, ofType: .string)
    )
    }
}

extension NewTeam: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
    public typealias IdentifierProtocol = DefaultModelIdentifier<NewTeam>
}
