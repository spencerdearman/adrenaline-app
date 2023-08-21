//
//  DataStoreAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/21/23.
//

import Foundation
import Amplify

func queryUsers() async -> [GraphUser] {
    print("Query users")
    
    do {
        let queryResult = try await Amplify.DataStore.query(NewUser.self)
        print("Successfully retrieved list of users")
        
        //            // convert [ LandmarkData ] to [ LandMark ]
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
