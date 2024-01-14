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
        user.favoritesIds.append(followingId)
        
        // If user is a coach, then append the followed user to their favorites order if they are
        // an Athlete
        if var coach = try await user.coach,
           let followingUser = try await queryAWSUserById(id: followingId),
           followingUser.accountType == "Athlete" {
            coach.favoritesOrder.append(coach.favoritesOrder.count)
            coach = try await saveToDataStore(object: coach)
            user.setCoach(coach)
        }
        
        let _ = try await saveToDataStore(object: user)
    } catch {
        print("Failed to follow user")
    }
}

private func renumberFavoritesOrder(order: [Int], removing idx: Int) -> [Int] {
    var result: [Int] = []
    
    // Maintains value if items before the removing idx, but decrements items after removing idx
    // and skips appending the removing idx
    for i in order {
        if i < idx {
            result.append(i)
        } else if i > idx {
            result.append(i - 1)
        }
    }
    
    return result
}

func unfollow(follower user: NewUser, unfollowingId: String) async {
    do {
        var user = user
        
        // If follower is a coach and unfollowing an athlete, update favoritesOrder
        if var coach = try await user.coach,
           let unfollowingUser = try await queryAWSUserById(id: unfollowingId),
           unfollowingUser.accountType == "Athlete" {
            // Find index associated with unfollowing user
            var idx: Int? = nil
            for (i, favId) in user.favoritesIds.enumerated() {
                if favId == unfollowingId {
                    idx = i
                    break
                }
            }
            
            guard let idx = idx else { throw NSError() }
            coach.favoritesOrder = renumberFavoritesOrder(order: coach.favoritesOrder, removing: idx)
            coach = try await saveToDataStore(object: coach)
            user.setCoach(coach)
        }
        
        user.favoritesIds = user.favoritesIds.filter { $0 != unfollowingId }
        let _ = try await saveToDataStore(object: user)
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
