//
//  GraphUserGraphFollowed.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import Foundation
import Amplify

struct GraphUserGraphFollowed: Hashable, Codable, Identifiable {
    var id: UUID = UUID()
    var graphUser: GraphUser
    var graphFollowed: GraphFollowed
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Added later, not generated code
extension GraphUserGraphFollowed {
    // construct from API Data
    init(from : NewUserNewFollowed)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create userFollowed, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        graphUser = GraphUser(from: from.newUser)
        graphFollowed = GraphFollowed(from: from.newFollowed)
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

// Added later, not generated code
extension NewUserNewFollowed {
    // construct from API Data
    init(from : GraphUserGraphFollowed)  {
        id = from.id.uuidString
        newUser = NewUser(from: from.graphUser)
        newFollowed = NewFollowed(from: from.graphFollowed)
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}
