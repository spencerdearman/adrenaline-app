//
//  PostsAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/23/23.
//

import Foundation
import Amplify
import SwiftUI

// Saves a Post object and updates the user's posts list; returns the updated
// User struct and the saved Post struct
func savePost(user: NewUser, post: Post) async throws -> (NewUser, Post) {
    let savedPost = try await saveToDataStore(object: post)
    print("Saved post: \(savedPost)")
    
    if let list = user.posts {
        try await list.fetch()
        user.posts = List<Post>.init(elements: list.elements + [savedPost])
    } else {
        user.posts = List<Post>.init(elements: [savedPost])
    }
    
    let savedUser = try await saveToDataStore(object: user)
    
    return (savedUser, savedPost)
}

// Deletes a post for a given user and removes it from the user's posts list;
// returns the updated User struct
func deletePost(user: NewUser, post: Post) async throws -> NewUser {
    if let list = user.posts {
        try await list.fetch()
        user.posts = List<Post>.init(elements: list.elements.filter { $0.id != post.id })
    }
    
    let savedUser = try await saveToDataStore(object: user)
    
    try await deleteFromDataStore(object: post)
    
    return savedUser
}

struct PostsAPITestView: View {
    var email: String
    @State var currentUser: NewUser?
    
    var body: some View {
        VStack {
            Button {
                Task {
                    if let user = currentUser {
                        let post = Post(creationDate: .now(), newuserID: user.id)
                        let (savedUser, _) = try await savePost(user: user, post: post)
                        currentUser = savedUser
                        try await currentUser?.posts?.fetch()
                        print(currentUser?.posts?.elements ?? "nil")
                    }
                }
            } label: {
                Text("Create Post")
            }
            
            Button {
                Task {
                    if let user = currentUser {
                        try await user.posts?.fetch()
                        guard let post = user.posts?.elements[0] else { return }
                        let savedUser = try await deletePost(user: user, post: post)
                        currentUser = savedUser
                        try await currentUser?.posts?.fetch()
                        print(currentUser?.posts?.elements ?? "nil")
                    }
                }
            } label: {
                Text("Delete Post")
            }
        }
        .onAppear {
            Task {
                let usersPredicate = NewUser.keys.email == email
                let users = await queryAWSUsers(where: usersPredicate)
                if users.count >= 1 {
                    currentUser = users[0]
                }
            }
        }
    }
}
