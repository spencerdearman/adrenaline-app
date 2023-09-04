//
//  FollowingAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import Foundation
import Amplify

func addFollowedToUser(user: NewUser, followed: NewFollowed) async {
    do {
        // Saves if email doesn't exist, otherwise returns cloud object to avoid duplication
        let savedFollowed = try await saveFollowed(followed: followed)
        print("saved followed id: \(savedFollowed.id)")
        // Skips add if user already follows the followed object
        let combos = user.followed ?? []
        try await combos.fetch()
        print("Combos:", combos.elements)
        if combos.elements.contains(where: { $0.newFollowed.id == savedFollowed.id }) { return }
        
        let combo = NewUserNewFollowed(newUser: user, newFollowed: savedFollowed)
        try await Amplify.DataStore.save(combo)
        
        if let list = user.followed {
            try await list.fetch()
            user.followed = List<NewUserNewFollowed>.init(elements: list.elements + [combo])
        } else {
            user.followed = List<NewUserNewFollowed>.init(elements: [combo])
        }
        
        if let list = savedFollowed.users {
            try await list.fetch()
            savedFollowed.users = List<NewUserNewFollowed>.init(elements: list.elements + [combo])
        } else {
            savedFollowed.users = List<NewUserNewFollowed>.init(elements: [combo])
        }
        
        try await Amplify.DataStore.save(user)
        print("saved user")
        try await Amplify.DataStore.save(savedFollowed)
        print("saved followed")
    } catch {
        print("Failed to add followed to user")
    }
}
