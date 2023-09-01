//
//  Enums.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/31/23.
//

import SwiftUI

enum AccountType: String, CaseIterable {
    case athlete = "Athlete"
    case coach = "Coach"
    case spectator = "Spectator"
}

enum WeightUnit: String, CaseIterable {
    case lb = "lb"
    case kg = "kg"
}

enum Gender: String, CaseIterable {
    case male = "M"
    case female = "F"
}

enum BasicInfoField: Int, Hashable, CaseIterable {
    case first
    case last
    case email
    case phone
    case password
    case repeatPassword
}

struct UserViewData: Equatable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var diveMeetsID: String?
    var accountType: String?
}

enum EventType: Int, CaseIterable {
    case one = 1
    case three = 3
    case platform = 5
}

enum SkillGraph: String, CaseIterable {
    case overall = "Overall"
    case one = "1-Meter"
    case three = "3-Meter"
    case platform = "Platform"
}

