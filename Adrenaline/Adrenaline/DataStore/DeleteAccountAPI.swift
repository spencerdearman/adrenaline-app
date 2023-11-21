//
//  DeleteAccountAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/21/23.
//

import Foundation
import Amplify

private func deleteDataStoreCoachOrAthlete(user: NewUser) async throws {
    
}

private func deleteDataStorePosts(user: NewUser) async throws {
    
}

private func deleteDataStoreMessages(user: NewUser) async throws {
    // Get linker table entries with the user in them
    let pred = MessageNewUser.keys.newuserID == user.id
    let messageNewUsers: [MessageNewUser] = try await query(where: pred)
    
    // Gets a set of unique message ids that are associated with the user
    let messageIds = Set(messageNewUsers.map { $0.messageID })
    
    // Deletes all linker table entries with the user in them
    for msgNewUser in messageNewUsers {
        try await deleteFromDataStore(object: msgNewUser)
    }
    
    // Deletes all Message entries if their id was in the linker table
    for msgId in messageIds {
        try await Amplify.DataStore.delete(Message.self, withId: msgId)
    }
}

private func deleteAccountDataStoreData(authUserId: String) async throws {
    let pred = NewUser.keys.id == authUserId
    let users = await queryAWSUsers(where: pred)
    if users.count != 1 { throw NSError() }
    
    let user = users[0]
    try await deleteDataStoreCoachOrAthlete(user: user)
    try await deleteDataStorePosts(user: user)
    try await deleteDataStoreMessages(user: user)
}

func deleteAccount(authUserId: String) async {
    do {
        try await deleteAccountDataStoreData(authUserId: authUserId)
        print("Successfully deleted user DataStore data")
        
        try await Amplify.Auth.deleteUser()
        print("Successfully deleted user")
    } catch let error as AuthError {
        print("Delete user failed with error \(error)")
    } catch {
        print("Unexpected error: \(error)")
    }
}
