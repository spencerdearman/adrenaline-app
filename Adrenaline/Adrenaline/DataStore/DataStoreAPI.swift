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

func saveUser(user: GraphUser) async throws -> NewUser {
    let newUser = NewUser(from: user)
    let savedUser = try await Amplify.DataStore.save(newUser)
    print("Saved user: \(savedUser.email)")
    
    return savedUser
}

func updateUserField(email: String, key: String, value: Any) async throws {
    let users = await queryUsers(where: NewUser.keys.email == email)
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
            case "followed":
                updatedUser.followed = value as! [String]
                break
            default:
                print("Invalid key in NewUser")
                return
        }
        
        let _ = try await saveUser(user: updatedUser)
    }
}

func deleteUserByEmail(email: String) async throws {
    for user in await queryUsers() {
        if user.email == email {
            let newUser = NewUser(from: user)
            try await Amplify.DataStore.delete(newUser)
            print("Deleted user: \(user.email)")
        }
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
