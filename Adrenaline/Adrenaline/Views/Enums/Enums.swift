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

enum SignupInfoField: Int, Hashable, CaseIterable {
    case email
    case password
    case confirmPassword
    case confirmationCode
    case firstName
    case lastName
    case phone
    case heightFeet
    case heightInches
    case weight
    case birthday
    case gradYear
    case highSchool
    case hometown
    case sat
    case act
    case gpa
    case gpaScale
    case coursework
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

