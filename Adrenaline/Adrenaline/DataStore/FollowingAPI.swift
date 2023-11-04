//
//  FollowingAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import Foundation
import Amplify

func follow(follower user: NewUser, followingId: String) async {
    do {
        print("Following: \(followingId)")
        user.favoritesIds.append(followingId)
        
        let savedUser = try await saveToDataStore(object: user)
        print("saved user \(savedUser)")
    } catch {
        print("Failed to follow user")
    }
}

func unfollow(follower user: NewUser, unfollowingId: String) async {
    do {
        print("Unfollowing: \(unfollowingId)")
        user.favoritesIds = user.favoritesIds.filter { $0 != unfollowingId }
        
        let savedUser = try await saveToDataStore(object: user)
        print("saved user \(savedUser)")
    } catch {
        print("Failed to unfollow user")
    }
}
