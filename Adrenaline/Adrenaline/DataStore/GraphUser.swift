//
//  GraphUser.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/28/23.
//

import Foundation
import Amplify

struct GraphUser: Hashable, Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var diveMeetsID: String?
    var accountType: String
    var followed: [String] = []
    var createdAt: String?
    var updatedAt: String?
    var athleteId: String?
    var coachId: String?
}


// Added later, not generated code
extension GraphUser {
    // construct from API Data
    init(from : NewUser)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected UUID)")
        }
        
        // assume all fields are non null.
        // real life project must spend more time thinking about null values and
        // maybe convert the above code (original Landmark class) to optionals
        // I am not doing it for this workshop as this would imply too many changes in UI code
        // MARK: - TODO
        
        id = i
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        phone = from.phone
        diveMeetsID = from.diveMeetsID
        accountType = from.accountType
        // TODO: fix this later
        followed = []
        createdAt = from.createdAt?.iso8601String
        updatedAt = from.updatedAt?.iso8601String
        athleteId = from.newUserAthleteId
        coachId = from.newUserCoachId
    }
}

extension NewUser {
    convenience init(from user: GraphUser) {
        self.init(id: user.id.uuidString,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  email: user.email,
                  phone: user.phone,
                  diveMeetsID: user.diveMeetsID,
                  accountType: user.accountType,
                  athlete: nil,
                  coach: nil,
                  // TODO: fix this
                  followed: [],
                  createdAt: nil,
                  updatedAt: nil,
                  newUserAthleteId: user.athleteId,
                  newUserCoachId: user.coachId)
    }
}
