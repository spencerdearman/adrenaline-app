//
//  PostsAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/23/23.
//

import Foundation
import Amplify
import SwiftUI

func getCurrentDateTime() -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd--HH:mm:ss"
    
    return df.string(from: Date.now)
}

// Attempts to upload an image to S3
func uploadImage(data: Data, email: String, name: String) async throws {
    let key = "images/\(email)/\(name).jpg"
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Image \(name) uploaded")
}

// Creates a Post object given a user, title, description, and potential videos and images data
// Note: This function saves images and videos to S3 to get the links and stop carrying the Data,
//       but this doesn't save to the DataStore until savePost() is called
func createPost(user: NewUser, caption: String, videosData: [String: Data],
                imagesData: [String: Data], idOrder: [String]) async throws -> Post {
    var videos: [Video]? = nil
    var images: [NewImage]? = nil
    let email = user.email.lowercased()
    
    let postId = UUID().uuidString
    
    do {
        for id in idOrder {
            if videosData.keys.contains(id) {
                try await uploadVideo(data: videosData[id]!, email: email, name: id)
                
                if videos == nil { videos = [] }
                videos?.append(Video(id: id, s3key: id, uploadDate: .now(), postID: postId))
            } else if imagesData.keys.contains(id) {
                try await uploadImage(data: imagesData[id]!, email: email, name: id)
                
                if images == nil { images = [] }
                images?.append(NewImage(id: id, s3key: id, uploadDate: .now(), postID: postId))
            }
        }
        
        let imagesList = images == nil ? nil : List<NewImage>.init(elements: images!)
        let videosList = videos == nil ? nil : List<Video>.init(elements: videos!)
        
        return Post(id: postId, caption: caption, creationDate: .now(),
                    images: imagesList, videos: videosList, newuserID: user.id)
    }
}

// Saves a Post object and updates the user's posts list; returns the updated
// User struct and the saved Post struct
// Note: This saves the associated images and videos with the Post to the DataStore before
//       saving the Post itself
func savePost(user: NewUser, post: Post) async throws -> (NewUser, Post) {
    if let videos = post.videos {
        try await videos.fetch()
        for video in videos {
            let _ = try await saveToDataStore(object: video)
        }
    }
    
    if let images = post.images {
        try await images.fetch()
        for image in images {
            let _ = try await saveToDataStore(object: image)
        }
    }
    
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
// Note: this also deletes the associated videos and images with the post to be deleted
func deletePost(user: NewUser, post: Post) async throws -> NewUser {
    if let list = user.posts {
        try await list.fetch()
        user.posts = List<Post>.init(elements: list.elements.filter { $0.id != post.id })
    }
    
    let savedUser = try await saveToDataStore(object: user)
    
    if let videos = post.videos {
        try await videos.fetch()
        for video in videos {
            let _ = try await deleteFromDataStore(object: video)
        }
    }
    
    if let images = post.images {
        try await images.fetch()
        for image in images {
            let _ = try await deleteFromDataStore(object: image)
        }
    }
    
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
