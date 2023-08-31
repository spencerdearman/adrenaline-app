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
    var followed: [GraphUserGraphFollowed]?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
    var athleteId: String?
    var coachId: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// Added later, not generated code
extension GraphUser {
    // construct from API Data
    init(from : NewUser)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        phone = from.phone
        diveMeetsID = from.diveMeetsID
        accountType = from.accountType
        
        if let list = from.followed {
            followed = list.map { GraphUserGraphFollowed(from: $0) }
        }
        createdAt = from.createdAt
        updatedAt = from.updatedAt
        athleteId = from.newUserAthleteId
        coachId = from.newUserCoachId
    }
}

extension NewUser {
    convenience init(from user: GraphUser) {
        var passFollowed: List<NewUserNewFollowed> = []
        if let followed = user.followed {
            passFollowed = List<NewUserNewFollowed>.init(elements: followed.map {
                NewUserNewFollowed(from: $0)
            })
        }
        
        self.init(id: user.id.uuidString,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  email: user.email,
                  phone: user.phone,
                  diveMeetsID: user.diveMeetsID,
                  accountType: user.accountType,
                  athlete: nil,
                  coach: nil,
                  followed: passFollowed,
                  createdAt: nil,
                  updatedAt: nil,
                  newUserAthleteId: user.athleteId,
                  newUserCoachId: user.coachId)
    }
}
