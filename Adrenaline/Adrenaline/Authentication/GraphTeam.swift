//
//  GraphTeam.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/28/23.
//
import Foundation
import Amplify

struct GraphTeam: Hashable, Codable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GraphTeam, rhs: GraphTeam) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID = UUID()
    var name: String
    var coach: CoachUser?
    var athletes: List<NewAthlete>?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
    var newTeamCoachId: String?
}

// Added later, not generated code
extension GraphTeam {
    // construct from API Data
    init(from : NewTeam)  {

        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create team, Invalid ID : \(from.id) (expected UUID)")
        }

        id = i
        name = from.name
        coach = from.coach
        athletes = from.athletes
        createdAt = from.createdAt
        updatedAt = from.updatedAt
        newTeamCoachId = from.newTeamCoachId
    }
}

extension NewTeam {
    convenience init(from team: GraphTeam) {
        self.init(id: team.id.uuidString,
                  name: team.name,
                  coach: team.coach,
                  athletes: [],
                  createdAt: nil,
                  updatedAt: nil,
                  newTeamCoachId: team.newTeamCoachId)
    }
}
