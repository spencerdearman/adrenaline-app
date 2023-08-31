//
//  DataStoreAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/21/23.
//

import Foundation
import Amplify

// Returns generated model list without converting to Swift class
func query<M: Model>(where predicate: QueryPredicate? = nil,
                     sortBy: QuerySortInput? = nil) async throws -> [M] {
    let queryResult = try await Amplify.DataStore.query(M.self, where: predicate,
                                                        sort: sortBy)
    
    return queryResult
}


// Returns GraphUser class list
func queryUsers(where predicate: QueryPredicate? = nil,
                sortBy: QuerySortInput? = nil) async -> [GraphUser] {
    do {
        let queryResult: [NewUser] = try await query(where: predicate, sortBy: sortBy)
        let result = queryResult.map { newUser in
            GraphUser.init(from: newUser)
        }
        return result
    } catch let error as DataStoreError {
        print("Failed to load data from DataStore : \(error)")
    } catch {
        print("Unexpected error while calling DataStore : \(error)")
    }
    
    return []
}

// Saves to DataStore without converting object from Swift class
// Note: updating is the same as saving an existing object, so this is also used for updating
func saveToDataStore<M: Model>(object: M) async throws -> M {
    let savedObject = try await Amplify.DataStore.save(object)
    
    return savedObject
}

func saveUser(user: GraphUser) async throws -> NewUser {
    let newUser = NewUser(from: user)
    let savedUser = try await saveToDataStore(object: newUser)
    print("Saved user: \(savedUser)")
    
    return savedUser
}

func saveAthlete(athlete: GraphAthlete) async throws -> NewAthlete {
    let newAthlete = NewAthlete(from: athlete)
    let savedAthlete = try await saveToDataStore(object: newAthlete)
    print("Saved athlete: \(savedAthlete)")
    
    return savedAthlete
}

func updateUserField(email: String, key: String, value: Any) async throws {
    let users: [NewUser] = try await query(where: NewUser.keys.email == email)
    print(users)
    for user in users {
        let updatedUser = user
        switch key {
            case "firstName":
                updatedUser.firstName = value as! String
                break
            case "lastName":
                updatedUser.lastName = value as! String
                break
            case "phone":
                updatedUser.phone = value as? String
                break
            case "accountType":
                updatedUser.accountType = value as! String
                break
            case "diveMeetsId":
                updatedUser.diveMeetsID = value as? String
                break
            case "followed":
                updatedUser.followed = value as? List<NewUserNewFollowed>
                break
            default:
                print("Invalid key in NewUser")
                return
        }
        
        let _ = try await saveToDataStore(object: updatedUser)
    }
}

func updateAthleteField(user: NewUser, key: String, value: Any) async throws {
    let athletes: [NewAthlete] = try await query(where: NewAthlete.keys.user == user as! EnumPersistable)
    print(athletes)
    for athlete in athletes {
        var updatedAthlete = athlete
        switch key {
        case "team":
            updatedAthlete.team = value as? NewTeam
            break
        case "college":
            updatedAthlete.college = value as! College?
            break
        case "heightFeet":
            updatedAthlete.heightFeet = value as! Int
            break
        case "heightInches":
            updatedAthlete.heightInches = value as! Int
            break
        case "weight":
            updatedAthlete.weight = value as! Int
            break
        case "weightUnit":
            updatedAthlete.weightUnit = value as! String
            break
        case "gender":
            updatedAthlete.gender = value as! String
            break
        case "age":
            updatedAthlete.age = value as! Int
            break
        case "graduationYear":
            updatedAthlete.graduationYear = value as! Int
            break
        case "highSchool":
            updatedAthlete.highSchool = value as! String
            break
        case "hometown":
            updatedAthlete.hometown = value as! String
            break
        case "springboardRating":
            updatedAthlete.springboardRating = value as? Double
            break
        case "platformRating":
            updatedAthlete.platformRating = value as? Double
            break
        case "totalRating":
            updatedAthlete.totalRating = value as? Double
            break
        case "dives":
                updatedAthlete.dives = value as? List<Dive> ?? []
            break
        case "videos":
            updatedAthlete.videos = value as? List<Video> ?? []
            break
        default:
            print("Invalid key in NewAthlete")
            return
        }
        
        let _ = try await saveToDataStore(object: updatedAthlete)
    }
}

func deleteFromDataStore<M: Model>(object: M) async throws {
    try await Amplify.DataStore.delete(object)
}

func deleteUserByEmail(email: String) async throws {
    for user in await queryUsers() {
        if user.email == email {
            let newUser = NewUser(from: user)
            try await deleteFromDataStore(object: newUser)
            print("Deleted user: \(user.email)")
        }
    }
}

struct GraphUser: Hashable, Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var diveMeetsID: String?
    var accountType: String
    var followed: [String] = []
    var createdAt: String?
    var updatedAt: String?
    var athleteId: String?
    var coachId: String?
}
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


// Added later, not generated code
extension GraphUser {
    // construct from API Data
    init(from : NewUser)  {
        
        guard let i = UUID(uuidString: from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected UUID)")
        }
        
        // assume all fields are non null.
        // real life project must spend more time thinking about null values and
        // maybe convert the above code (original Landmark class) to optionals
        // I am not doing it for this workshop as this would imply too many changes in UI code
        // MARK: - TODO
        
        id = i
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        phone = from.phone
        diveMeetsID = from.diveMeetsID
        accountType = from.accountType
        // TODO: fix this later
        followed = []
        createdAt = from.createdAt?.iso8601String
        updatedAt = from.updatedAt?.iso8601String
        athleteId = from.newUserAthleteId
        coachId = from.newUserCoachId
    }
}

extension NewUser {
    convenience init(from user: GraphUser) {
        self.init(id: user.id.uuidString,
                  firstName: user.firstName,
                  lastName: user.lastName,
                  email: user.email,
                  phone: user.phone,
                  diveMeetsID: user.diveMeetsID,
                  accountType: user.accountType,
                  athlete: nil,
                  coach: nil,
                  // TODO: fix this
                  followed: [],
                  createdAt: nil,
                  updatedAt: nil,
                  newUserAthleteId: user.athleteId,
                  newUserCoachId: user.coachId)
    }
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
