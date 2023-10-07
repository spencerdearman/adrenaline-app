//
//  GraphFollowed.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import Foundation
import Amplify

struct GraphFollowed: Hashable, Identifiable {
    var id: UUID = UUID()
    var email: String
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
        email = from.email
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

// Added later, not generated code
extension NewFollowed {
    // construct from API Data
    convenience init(from : GraphFollowed)  {
        self.init(id: from.id.uuidString,
                  email: from.email,
                  createdAt: from.createdAt,
                  updatedAt: from.updatedAt)
    }
}
