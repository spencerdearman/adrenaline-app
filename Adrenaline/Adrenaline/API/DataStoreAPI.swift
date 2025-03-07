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

func queryAWSUsers(where predicate: QueryPredicate? = nil,
                   sortBy: QuerySortInput? = nil) async -> [NewUser] {
    do {
        let queryResult: [NewUser] = try await query(where: predicate, sortBy: sortBy)
        return queryResult
    } catch let error as DataStoreError {
        print("Failed to load data from DataStore : \(error)")
    } catch {
        print("Unexpected error while calling DataStore : \(error)")
    }
    return []
}

func queryAWSUserById(id: String) async throws -> NewUser? {
    return try await Amplify.DataStore.query(NewUser.self, byId: id)
}

func queryAWSAthletes(where predicate: QueryPredicate? = nil,
                      sortBy: QuerySortInput? = nil) async -> [NewAthlete] {
    do {
        let queryResult: [NewAthlete] = try await query(where: predicate, sortBy: sortBy)
        return queryResult
    } catch let error as DataStoreError {
        print("Failed to load data from DataStore : \(error)")
    } catch {
        print("Unexpected error while calling DataStore : \(error)")
    }
    return []
}

func queryAWSAthleteById(id: String) async throws -> NewAthlete? {
    try await Amplify.DataStore.query(NewAthlete.self, byId: id)
}

func queryAWSCoachById(id: String) async throws -> CoachUser? {
    try await Amplify.DataStore.query(CoachUser.self, byId: id)
}

func queryAWSCollegeById(id: String) async throws -> College? {
    try await Amplify.DataStore.query(College.self, byId: id)
}

func getCollegeId(name: String) -> String {
    return name.lowercased().replacingOccurrences(of: " ", with: "-")
}

// Saves to DataStore without converting object from Swift class
// Note: updating is the same as saving an existing object, so this is also used for updating
func saveToDataStore<M: Model>(object: M) async throws -> M {
    let savedObject = try await Amplify.DataStore.save(object)
    
    return savedObject
}

func updateUserField(email: String, key: String, value: Any) async throws {
    let users: [NewUser] = try await query(where: NewUser.keys.email == email)
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
            case "favoritesIds":
                updatedUser.favoritesIds = value as? [String] ?? []
                break
            default:
                print("Invalid key in NewUser")
                return
        }
        
        let _ = try await saveToDataStore(object: updatedUser)
    }
}

func updateAthleteField(user: NewUser, key: String, value: Any) async throws {
    let athletes: [NewAthlete] = try await query(where: NewAthlete.keys.user == user as! EnumPersistable)
    print(athletes)
    for athlete in athletes {
        var updatedAthlete = athlete
        switch key {
            case "team":
                updatedAthlete.setTeam(value as? NewTeam)
                break
            case "college":
                updatedAthlete.setCollege(value as! College?)
                break
            case "heightFeet":
                updatedAthlete.heightFeet = value as! Int
                break
            case "heightInches":
                updatedAthlete.heightInches = value as! Int
                break
            case "weight":
                updatedAthlete.weight = value as! Int
                break
            case "weightUnit":
                updatedAthlete.weightUnit = value as! String
                break
            case "gender":
                updatedAthlete.gender = value as! String
                break
            case "graduationYear":
                updatedAthlete.graduationYear = value as! Int
                break
            case "highSchool":
                updatedAthlete.highSchool = value as! String
                break
            case "hometown":
                updatedAthlete.hometown = value as! String
                break
            case "springboardRating":
                updatedAthlete.springboardRating = value as? Double
                break
            case "platformRating":
                updatedAthlete.platformRating = value as? Double
                break
            case "totalRating":
                updatedAthlete.totalRating = value as? Double
                break
            case "dives":
                updatedAthlete.dives = value as? List<Dive> ?? []
                break
            default:
                print("Invalid key in NewAthlete")
                return
        }
        
        let _ = try await saveToDataStore(object: updatedAthlete)
    }
}

func deleteFromDataStore<M: Model>(object: M) async throws {
    try await Amplify.DataStore.delete(object)
}

func deleteUserByEmail(email: String) async throws {
    for user in await queryAWSUsers() {
        if user.email == email {
            try await deleteFromDataStore(object: user)
            print("Deleted user: \(user.email)")
        }
    }
}

func getUserByEmail(email: String) async throws -> NewUser? {
    let usersPredicate = NewUser.keys.email == email
    let users = await queryAWSUsers(where: usersPredicate)
    if users.count >= 1 {
        return users[0]
    }
    
    return nil
}

func clearLocalDataStore() async throws {
    try await Amplify.DataStore.start()
    try await Amplify.DataStore.stop()
    try await Amplify.DataStore.clear()
    try await Amplify.DataStore.start()
}

func getAthleteUsersByFavoritesIds(ids: [String]) async throws -> [NewUser] {
    var pred: QueryPredicateGroup
    if ids.count == 0 { return [] }
    else if ids.count == 1 {
        let user = try await queryAWSUserById(id: ids[0])
        if let user = user, user.accountType == "Athlete" {
            return [user]
        } else {
            return []
        }
    }
    
    pred = (NewUser.keys.id == ids[0]).or(NewUser.keys.id == ids[1])
    
    if ids.count > 2 {
        for id in ids[2...] {
            pred = pred.or(NewUser.keys.id == id)
        }
    }
    
    // Query for users
    let users = await queryAWSUsers(where: pred).filter { $0.accountType == "Athlete" }
    let userIds = Set(users.map { $0.id })
    
    // Get resulting input ids to maintain request sort order
    let finalInputIds = ids.filter({ userIds.contains($0) })
    let idToIndex = finalInputIds.enumerated()
        .reduce(into: [String: Int]()) { result, item in
        let (index, id) = item
        result[id] = index
    }
    
    // Combine default sort index with NewUser object
    var order: [(Int, NewUser)] = []
    for user in users {
        if let idx = idToIndex[user.id] {
            order.append((idx, user))
        }
    }
    
    // Return sorted list of NewUser objects
    return order.sorted { $0.0 < $1.0 }.map { $0.1 }
}

func getUsersByIds(ids: [String]) async throws -> [NewUser] {
    var pred: QueryPredicateGroup
    if ids.count == 0 { return [] }
    else if ids.count == 1 {
        let user = try await queryAWSUserById(id: ids[0])
        if let user = user {
            return [user]
        } else {
            return []
        }
    }
    
    pred = (NewUser.keys.id == ids[0]).or(NewUser.keys.id == ids[1])
    
    if ids.count > 2 {
        for id in ids[2...] {
            pred = pred.or(NewUser.keys.id == id)
        }
    }
    
    // Query for users
    let users = await queryAWSUsers(where: pred)
    let userIds = Set(users.map { $0.id })
    
    // Get resulting input ids to maintain request sort order
    let finalInputIds = ids.filter({ userIds.contains($0) })
    let idToIndex = finalInputIds.enumerated()
        .reduce(into: [String: Int]()) { result, item in
            let (index, id) = item
            result[id] = index
        }
    
    // Combine default sort index with NewUser object
    var order: [(Int, NewUser)] = []
    for user in users {
        if let idx = idToIndex[user.id] {
            order.append((idx, user))
        }
    }
    
    // Return sorted list of NewUser objects
    return order.sorted { $0.0 < $1.0 }.map { $0.1 }
}

// Returns posts in dictionary form, with key being the user id and list of posts in reverse
// chronological order as value
func getPostsByUserIds(ids: [String]) async throws -> [String: [Post]] {
    var result: [String: [Post]] = [:]
    var pred: QueryPredicateGroup
    if ids.count == 0 { return [:] }
    else if ids.count == 1 {
        let pred = Post.keys.newuserID == ids[0]
        let posts: [Post] = try await query(where: pred)
        return [ids[0]: posts.sorted {
            $0.creationDate > $1.creationDate
        }]
    }
    
    pred = (Post.keys.newuserID == ids[0]).or(Post.keys.newuserID == ids[1])
    
    if ids.count > 2 {
        for id in ids[2...] {
            pred = pred.or(Post.keys.newuserID == id)
        }
    }
    
    let allPosts: [Post] = try await query(where: pred)
    for id in ids {
        let userPosts = allPosts.filter { $0.newuserID == id }.sorted {
            $0.creationDate > $1.creationDate
        }
        
        result[id] = userPosts
    }
    
    return result
}

// Returns posts in array form with posts in reverse chronological order. This is meant for the
// feed page, where the owning user does not matter when listing the posts
func getFeedPostsByUserIds(ids: [String]) async throws -> [(NewUser, Post)] {
    var pred: QueryPredicateGroup
    if ids.count == 0 { return [] }
    else if ids.count == 1 {
        let pred = Post.keys.newuserID == ids[0]
        let posts: [Post] = try await query(where: pred)
        guard let user = try await queryAWSUserById(id: ids[0]) else { return [] }
        return posts.map { (user, $0) }.sorted {
            $0.1.creationDate > $1.1.creationDate
        }
    }
    
    pred = (Post.keys.newuserID == ids[0]).or(Post.keys.newuserID == ids[1])
    
    if ids.count > 2 {
        for id in ids[2...] {
            pred = pred.or(Post.keys.newuserID == id)
        }
    }
    
    let allPosts: [Post] = try await query(where: pred)
    let userIds = allPosts.map { $0.newuserID }
    let users = try await getUsersByIds(ids: userIds)
    var usersDict: [String: NewUser] = [:]
    for user in users {
        usersDict[user.id] = user
    }
    
    var tuples: [(NewUser, Post)] = []
    for post in allPosts {
        if let user = usersDict[post.newuserID] {
            tuples.append((user, post))
        }
    }
    
    return tuples.sorted {
        $0.1.creationDate > $1.1.creationDate
    }
}
