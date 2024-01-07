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
        var user = user
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
        var user = user
        print("Unfollowing: \(unfollowingId)")
        user.favoritesIds = user.favoritesIds.filter { $0 != unfollowingId }
        
        let savedUser = try await saveToDataStore(object: user)
        print("saved user \(savedUser)")
    } catch {
        print("Failed to unfollow user")
    }
}

extension NewUser: Hashable, Identifiable {
    public static func == (lhs: NewUser, rhs: NewUser) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
