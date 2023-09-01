//
//  GraphMeet.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/28/23.
//

import Foundation
import Amplify

struct GraphMeet: Hashable, Codable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GraphMeet, rhs: GraphMeet) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: UUID = UUID()
    var meetID: Int
    var name: String
    var organization: String?
    var startDate: Temporal.Date
    var endDate: Temporal.Date
    var city: String
    var state: String
    var country: String
    var link: String
    var meetType: Int
    var events: List<NewEvent>?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
}

// Added later, not generated code
extension GraphMeet {
    // construct from API Data
    init(from : NewMeet)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create meet, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        meetID = from.meetID
        name = from.name
        organization = from.organization
        startDate = from.startDate
        endDate = from.endDate
        city = from.city
        state = from.state
        country = from.country
        link = from.link
        meetType = from.meetType
        events = from.events
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

extension NewMeet {
    init(from meet: GraphMeet) {
        self.init(id: meet.id.uuidString,
                  meetID: meet.meetID,
                  name: meet.name,
                  organization: nil,
                  startDate: meet.startDate,
                  endDate: meet.endDate,
                  city: meet.city,
                  state: meet.state,
                  country: meet.country,
                  link: meet.link,
                  meetType: meet.meetType,
                  events: meet.events ?? [],
                  createdAt: nil,
                  updatedAt: nil)
    }
}
