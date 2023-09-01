//
//  GraphAthlete.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/1/23.
//

import Foundation
import Amplify

struct GraphAthlete: Codable, Identifiable {
    var id: UUID = UUID()
    var user: NewUser
    var team: NewTeam?
    var college: College?
    var heightFeet: Int
    var heightInches: Int
    var weight: Int
    var weightUnit: String
    var gender: String
    var age: Int
    var graduationYear: Int
    var highSchool: String
    var hometown: String
    var springboardRating: Double?
    var platformRating: Double?
    var totalRating: Double?
    var dives: List<Dive>?
    var videos: List<Video>?
    var createdAt: Temporal.DateTime?
    var updatedAt: Temporal.DateTime?
}

extension GraphAthlete {
    // construct from API Data
    init(from : NewAthlete) {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected UUID)")
        }
        
        id = i
        user = from.user
        team = from.team
        college = from.college
        heightFeet = from.heightFeet
        heightInches = from.heightInches
        weight = from.weight
        weightUnit = from.weightUnit
        gender = from.gender
        age = from.age
        graduationYear = from.graduationYear
        highSchool = from.highSchool
        hometown = from.hometown
        springboardRating = from.springboardRating
        platformRating = from.platformRating
        totalRating = from.totalRating
        dives = from.dives
        videos = from.videos
        createdAt = from.createdAt
        updatedAt = from.updatedAt
    }
}

extension NewAthlete {
    init(from athlete: GraphAthlete) {
        self.init(id: athlete.id.uuidString,
                  user: athlete.user,
                  team: athlete.team,
                  college: athlete.college,
                  heightFeet: athlete.heightFeet,
                  heightInches: athlete.heightInches,
                  weight: athlete.weight,
                  weightUnit: athlete.weightUnit,
                  gender: athlete.gender,
                  age: athlete.age,
                  graduationYear: athlete.graduationYear,
                  highSchool: athlete.highSchool,
                  hometown: athlete.hometown,
                  springboardRating: athlete.springboardRating,
                  platformRating: athlete.platformRating,
                  totalRating: athlete.totalRating,
                  dives: athlete.dives ?? [],
                  videos: athlete.videos ?? [],
                  createdAt: athlete.createdAt,
                  updatedAt: athlete.updatedAt)
    }
}
