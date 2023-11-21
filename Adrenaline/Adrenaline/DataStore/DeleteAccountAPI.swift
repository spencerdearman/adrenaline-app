//
//  DeleteAccountAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/21/23.
//

import Foundation
import Amplify

// Remove all data nested with CoachUser object associated with the user
private func deleteDataStoreCoach(user: NewUser) async throws {
    
}

// Remove all data nested with NewAthlete object associated with the user
private func deleteDataStoreAthlete(user: NewUser) async throws {
    
}

// Remove all data nested within NewAthlete or CoachUser object associated with the user
private func deleteDataStoreCoachOrAthlete(user: NewUser) async throws {
    if user.coach != nil {
        return try await deleteDataStoreCoach(user: user)
    } else if user.athlete != nil {
        return try await deleteDataStoreAthlete(user: user)
    }
}

private func deleteUsersSaving(user: NewUser, post: Post) async throws {
    guard let usersSaving = post.usersSaving else { return }
    try await usersSaving.fetch()
    
    // Iterates over every user that saved this post and removes it from their savedPosts list
    for saving in usersSaving {
        let result = try await Amplify.DataStore.query(NewUser.self, byId: saving.newuserID)
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

// Remove user id String from all users that favorite them
private func deleteDataStoreFavorites(user: NewUser) async throws {
    // Get all users that have favorited the given user
    let result = try await Amplify.DataStore.query(NewUser.self,
                                                   where: NewUser.keys.favoritesIds.contains(user.id))
    
    // For each user, remove the given user from their favorites and update their favoritesIds list
    // in the DataStore
    for user in result {
        user.favoritesIds = user.favoritesIds.filter { $0 != user.id }
        let _ = try await saveToDataStore(object: user)
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
    try await deleteDataStoreFavorites(user: user)
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
