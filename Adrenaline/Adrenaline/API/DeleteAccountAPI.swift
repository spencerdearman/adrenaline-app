//
//  DeleteAccountAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/21/23.
//

import Foundation
import Amplify

enum DeleteAccountAPIError: Error {
    case userNotFoundError(String)
}

// Remove all data nested with CoachUser object associated with the user
private func deleteDataStoreCoach(coach: CoachUser) async throws {
    if var team = try await coach.team {
        // Remove coach from team association and update team in DataStore
        team.setCoach()
        let _ = try await saveToDataStore(object: team)
    }
    
    // Remove coach from DataStore
    try await deleteFromDataStore(object: coach)
}

// Remove all data nested within Dive objects or where Dive appears in NewEvent objects
private func deleteDataStoreDives(dives: [Dive]) async throws {
    // Iterate through all dives and remove their associations
    for dive in dives {
        // Remove all judge scores associated with that dive
        if let scores = dive.scores {
            try await scores.fetch()
            for score in scores.elements {
                try await deleteFromDataStore(object: score)
            }
        }
        
        // Get event where the current dive was performed
        if var event = try await Amplify.DataStore.query(NewEvent.self, byId: dive.neweventID),
           let dives = event.dives {
            // Get current event dives and filter out current dive
            try await dives.fetch()
            event.dives = List<Dive>.init(elements: dives.elements.filter { $0.id != dive.id })
            
            // Update event in DataStore with current dive removed
            let _ = try await saveToDataStore(object: event)
        }
    }
}

// Remove all data nested with NewAthlete object associated with the user
private func deleteDataStoreAthlete(athlete: NewAthlete) async throws {
    // Update team to remove association of this athlete
    if var team = try await athlete.team, let athletes = team.athletes {
        team.athletes = List<NewAthlete>.init(elements: athletes.elements.filter { $0.id != athlete.id })
        let _ = try await saveToDataStore(object: team)
    }
    
    // Update college to remove association of this athlete
    if var college = try await athlete.college, let athletes = college.athletes {
        college.athletes = List<NewAthlete>.init(elements: athletes.elements.filter { $0.id != athlete.id })
        let _ = try await saveToDataStore(object: college)
    }
    
    // Remove dives with associated judge scores and events in meets
    if let dives = athlete.dives {
        try await dives.fetch()
        try await deleteDataStoreDives(dives: dives.elements)
    }
    
    // Remove athlete from DataStore
    try await deleteFromDataStore(object: athlete)
}

// Remove all data nested within NewAthlete or CoachUser object associated with the user
private func deleteDataStoreCoachOrAthlete(user: NewUser) async throws {
    if let coach = try await user.coach {
        return try await deleteDataStoreCoach(coach: coach)
    } else if let athlete = try await user.athlete {
        return try await deleteDataStoreAthlete(athlete: athlete)
    }
}

private func deleteUsersSaving(user: NewUser, post: Post) async throws {
    guard let usersSaving = post.usersSaving else { return }
    try await usersSaving.fetch()
    
    // Iterates over every user that saved this post and removes it from their savedPosts list
    for saving in usersSaving {
        let result = try await queryAWSUserById(id: saving.newuserID)
        guard var user = result else { continue }
        guard let savedPosts = user.savedPosts else { continue }
        try await savedPosts.fetch()
        
        // Removes post from savedPosts of user
        user.savedPosts = List<UserSavedPost>.init(elements: savedPosts.elements.filter {
            $0.postID != post.id
        })
        
        // Update user with post removed from their savedPosts list
        let _ = try await saveToDataStore(object: user)
        
        // Remove UserSavedPost from DataStore
        try await deleteFromDataStore(object: saving)
    }
}

// Remove all Post data from DataStore and S3 associated with the given user
private func deleteDataStorePosts(user: NewUser) async throws {
    guard let posts = user.posts else { return }
    try await posts.fetch()
    
    // Iterate over videos and images of each post before deleting Post object itself
    for post in posts.elements {
        // Get videos from post
        if let videos = post.videos {
            try await videos.fetch()
            
            // Delete each video from S3 and from DataStore
            for video in videos.elements {
                try await removeVideoFromS3(email: user.email, videoId: video.id)
                try await deleteFromDataStore(object: video)
            }
        }
        
        // Get images from post
        if let images = post.images {
            try await images.fetch()
            
            // Delete each image from S3 and from DataStore
            for image in images.elements {
                try await removeImageFromS3(email: user.email, imageId: image.id)
                try await deleteFromDataStore(object: image)
            }
        }
        
        // Remove all saved post association from other users to this post
        try await deleteUsersSaving(user: user, post: post)
        
        // Delete Post object from DataStore
        try await deleteFromDataStore(object: post)
    }
}

// Remove all Message and MessageNewUser data associated with the user
private func deleteDataStoreMessages(user: NewUser) async throws {
    // Get linker table entries with the user in them
    let pred = MessageNewUser.keys.newuserID == user.id
    let userMessageNewUsers: [MessageNewUser] = try await query(where: pred)
    
    // Gets a set of unique message ids that are associated with the user
    let messageIds = Set(userMessageNewUsers.map { $0.messageID })
    
    // Deletes all linker table entries with message ids associated with the user.
    // This deletes messages exchanged with the user (both sent and received, where the user's id
    // would not be associated with the MessageNewUser entry)
    for msg in messageIds {
        let pred = MessageNewUser.keys.messageID == msg
        let msgNewUsers: [MessageNewUser] = try await query(where: pred)
        
        for msgNewUser in msgNewUsers {
            try await deleteFromDataStore(object: msgNewUser)
        }
    }
    
    // Deletes all Message entries if their id was in the linker table and somehow associated with
    // the user
    for msgId in messageIds {
        try await Amplify.DataStore.delete(Message.self, withId: msgId)
    }
}

// Remove user id String from all users that favorite them
private func deleteDataStoreFavorites(user: NewUser) async throws {
    // Get all users that have favorited the given user
    let result = try await Amplify.DataStore.query(NewUser.self,
                                                   where: NewUser.keys.favoritesIds.contains(user.id))
    
    // For each user, remove the given user from their favorites and update their favoritesIds list
    // in the DataStore
    for var user in result {
        user.favoritesIds = user.favoritesIds.filter { $0 != user.id }
        let _ = try await saveToDataStore(object: user)
    }
}

// Remove profile picture from S3
private func deleteProfilePicture(user: NewUser) async throws {
    try await Amplify.Storage.remove(key: "profile-pictures/\(user.id).jpg")
}

// Removes all data in DataStore and S3 associated with a NewUser given authUserId
private func deleteAccountDataStoreData(authUserId: String) async throws {
    // Get user object from authUserId
    let pred = NewUser.keys.id == authUserId
    let users = await queryAWSUsers(where: pred)
    if users.count != 1 { throw DeleteAccountAPIError.userNotFoundError("User count was not 1") }
    let user = users[0]
    
    // Delete associated DataStore and S3 data for the user
    try await deleteDataStoreCoachOrAthlete(user: user)
    try await deleteDataStorePosts(user: user)
    try await deleteDataStoreMessages(user: user)
    try await deleteDataStoreFavorites(user: user)
    try await deleteProfilePicture(user: user)
    
    // Delete user object itself
    try await deleteFromDataStore(object: user)
}

func deleteAccount(authUserId: String) async {
    do {
        do {
            // Delete associated DataStore and S3 data for user
            try await deleteAccountDataStoreData(authUserId: authUserId)
            print("Successfully deleted user DataStore data")
        } catch let error as DeleteAccountAPIError {
            // If userNotFoundError, continue without rethrowing
            if case let DeleteAccountAPIError.userNotFoundError(string) = error {
                print("User was not present, continuing...")
            } else {
                print("Failed to delete user DataStore data - \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("Failed to delete user DataStore data - \(error.localizedDescription)")
            throw error
        }
        
        // Sleep to give DataStore time to sync to the cloud
        try await Task.sleep(seconds: 5.0)
        
        // Clear UserDefaults except signupCompleted before forcefully deleting user and signing out
        // Note: keep signupCompleted to avoid returning to signupSequence on deletion
        // https://stackoverflow.com/a/43402172/22068672
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach {
            if $0 != "signupCompleted" { defaults.removeObject(forKey: $0) }
        }
        
        // Delete user Auth account
        try await Amplify.Auth.deleteUser()
        print("Successfully deleted user")
    } catch let error as AuthError {
        if error.errorDescription.contains("no user signed in") {
            print("Attempting to delete unconfirmed user")
            do {
                try await deleteUnconfirmedUser(authUserId: authUserId)
            } catch let err {
                print("Failed to delete unconfirmed user: \(err)")
            }
        }
        print("Delete user failed with error \(error)")
    } catch {
        print("Unexpected error: \(error)")
    }
}
