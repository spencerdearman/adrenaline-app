//
//  GraphCollege.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/28/23.
//

import Foundation
import Amplify

struct GraphCollege: Hashable, Codable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GraphCollege, rhs: GraphCollege) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: UUID = UUID()
    var name: String
    var imageLink: String
    var athletes: List<NewAthlete>?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
}

// Added later, not generated code
extension GraphCollege {
    // construct from API Data
    init(from : College)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create college, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        name = from.name
        imageLink = from.imageLink
        athletes = from.athletes
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

extension College {
    init(from college: GraphCollege) {
        self.init(id: college.id.uuidString,
                  name: college.name,
                  imageLink: college.imageLink,
                  athletes: [],
                  createdAt: nil,
                  updatedAt: nil)
    }
}
