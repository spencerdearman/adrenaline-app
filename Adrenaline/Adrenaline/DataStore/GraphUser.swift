//
//  GraphUser.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/28/23.
//

import Foundation
import Amplify

class GraphUser: ObservableObject, Hashable, Identifiable {
    static func == (lhs: GraphUser, rhs: GraphUser) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID = UUID(), firstName: String, lastName: String, email: String, phone: String? = nil, diveMeetsID: String? = nil, accountType: String, followed: List<NewUserNewFollowed>? = nil, createdAt: Temporal.DateTime? = nil, updatedAt: Temporal.DateTime? = nil, newUserAthleteId: String? = nil, newUserCoachId: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.diveMeetsID = diveMeetsID
        self.accountType = accountType
        
        self.followed = followed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.athleteId = newUserAthleteId
        self.coachId = newUserCoachId
    }
    
    @Published var id: UUID = UUID()
    @Published var firstName: String
    @Published var lastName: String
    @Published var email: String
    @Published var phone: String?
    @Published var diveMeetsID: String?
    @Published var accountType: String
    @Published var followed: List<NewUserNewFollowed>?
    @Published var createdAt: Temporal.DateTime?
    @Published var updatedAt: Temporal.DateTime?
    @Published var athleteId: String?
    @Published var coachId: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// Added later, not generated code
extension GraphUser {
    // construct from API Data
    convenience init(from : NewUser)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected UUID)")
        }
        
        self.init(id:i,
                  firstName: from.firstName,
                  lastName: from.lastName,
                  email: from.email,
                  phone: from.phone,
                  diveMeetsID: from.diveMeetsID,
                  accountType: from.accountType,
                  followed: from.followed,
                  createdAt: from.createdAt,
                  updatedAt: from.updatedAt,
                  newUserAthleteId: from.newUserAthleteId,
                  newUserCoachId: from.newUserCoachId)
    }
}

extension NewUser {
    convenience init(from user: GraphUser) {
//        var passFollowed: List<NewUserNewFollowed> = []
//        if let followed = user.followed {
//            passFollowed = List<NewUserNewFollowed>.init(elements: followed.map {
//                NewUserNewFollowed(from: $0)
//            })
//        }
        
        self.init(id: user.id.uuidString,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  email: user.email,
                  phone: user.phone,
                  diveMeetsID: user.diveMeetsID,
                  accountType: user.accountType,
                  athlete: nil,
                  coach: nil,
                  followed: user.followed ?? [],
                  createdAt: nil,
                  updatedAt: nil,
                  newUserAthleteId: user.athleteId,
                  newUserCoachId: user.coachId)
    }
}
