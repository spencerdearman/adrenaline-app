//
//  GraphFollowed.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import Foundation
import Amplify

struct GraphFollowed: Hashable, Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String?
    var diveMeetsID: String?
    var users: [GraphUserGraphFollowed]?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Added later, not generated code
extension GraphFollowed {
    // construct from API Data
    init(from : NewFollowed)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create followed, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        diveMeetsID = from.diveMeetsID
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

// Added later, not generated code
extension NewFollowed {
    // construct from API Data
    init(from : GraphFollowed)  {
        id = from.id.uuidString
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        diveMeetsID = from.diveMeetsID
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}
