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
        let combos = user.followed ?? []
        if combos.elements.contains(where: { $0.id == followed.id }) { return }
        let combo = NewUserNewFollowed(newUser: user, newFollowed: followed)
        try await Amplify.DataStore.save(combo)
        
        if let list = user.followed {
            user.followed = List<NewUserNewFollowed>.init(elements: list.elements + [combo])
        } else {
            user.followed = List<NewUserNewFollowed>.init(elements: [combo])
        }
        
        if let list = followed.users {
            followed.users = List<NewUserNewFollowed>.init(elements: list.elements + [combo])
        } else {
            followed.users = List<NewUserNewFollowed>.init(elements: [combo])
        }
        
        try await Amplify.DataStore.save(user)
        try await Amplify.DataStore.save(followed)
    } catch {
        print("Failed to add followed to user")
    }
}
