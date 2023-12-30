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

func queryAWSUsers(where predicate: QueryPredicate? = nil,
                   sortBy: QuerySortInput? = nil) async -> [NewUser] {
    do {
        let queryResult: [NewUser] = try await query(where: predicate, sortBy: sortBy)
        return queryResult
    } catch let error as DataStoreError {
        print("Failed to load data from DataStore : \(error)")
    } catch {
        print("Unexpected error while calling DataStore : \(error)")
    }
    return []
}

func queryAWSAthletes(where predicate: QueryPredicate? = nil,
                      sortBy: QuerySortInput? = nil) async -> [NewAthlete] {
    do {
        let queryResult: [NewAthlete] = try await query(where: predicate, sortBy: sortBy)
        return queryResult
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

func updateUserField(email: String, key: String, value: Any) async throws {
    let users: [NewUser] = try await query(where: NewUser.keys.email == email)
    print(users)
    for user in users {
        var updatedUser = user
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
            case "favoritesIds":
                updatedUser.favoritesIds = value as? [String] ?? []
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
                updatedAthlete.setTeam(value as? NewTeam)
                break
            case "college":
                updatedAthlete.setCollege(value as! College?)
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
    for user in await queryAWSUsers() {
        if user.email == email {
            try await deleteFromDataStore(object: user)
            print("Deleted user: \(user.email)")
        }
    }
}

func getUserByEmail(email: String) async throws -> NewUser? {
    let usersPredicate = NewUser.keys.email == email
    let users = await queryAWSUsers(where: usersPredicate)
    if users.count >= 1 {
        return users[0]
    }
    
    return nil
}

func clearLocalDataStore() async throws {
    try await Amplify.DataStore.start()
    try await Amplify.DataStore.stop()
    try await Amplify.DataStore.clear()
    try await Amplify.DataStore.start()
}
