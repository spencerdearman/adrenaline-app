//
//  PostsAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/23/23.
//

import Foundation
import Amplify
import SwiftUI

enum PostError: Error {
    case videoTooLong
}

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

// Deletes locally stored video files
func removeLocalVideos(email: String, videoIds: [String]) {
    for name in videoIds {
        let url = getVideoPathURL(email: email, name: name)
        let compressed = getCompressedFileURL(email: email, name: name)
        do {
            try FileManager.default.removeItem(at: url)
            
            if FileManager.default.fileExists(atPath: compressed.absoluteString) {
                try FileManager.default.removeItem(at: compressed)
            }
        } catch {
            print("Failed to remove data at URL \(url)")
        }
    }
}

// Creates a Post object given a user, title, description, and potential videos and images data
// Note: This function saves images and videos to S3 to get the links and stop carrying the Data,
//       but this doesn't save to the DataStore until savePost() is called
func createPost(user: NewUser, caption: String, videosData: [String: Data],
                imagesData: [String: Data], idOrder: [String], isCoachesOnly: Bool) async throws -> Post {
    var videos: [Video]? = nil
    var images: [NewImage]? = nil
    let email = user.email.lowercased()
    // Limit video duration to 3 minutes
    let maxVideoDurationSeconds: Double = 180
    
    let postId = UUID().uuidString
    
    // Preliminary check on videos to be sure they conform to length guardrail before any uploads
    // are started
    for (id, _) in videosData {
        if try await getVideoDurationSeconds(url: getVideoPathURL(email: email, name: id))
            > maxVideoDurationSeconds {
            print("Video \(id) is too long, aborting...")
            throw PostError.videoTooLong
        }
    }
    
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
                images: imagesList, videos: videosList, newuserID: user.id,
                isCoachesOnly: isCoachesOnly)
}

// Saves a Post object and updates the user's posts list; returns the updated
// User struct and the saved Post struct
// Note: This saves the associated images and videos with the Post to the DataStore before
//       saving the Post itself
func savePost(user: NewUser, post: Post) async throws -> (NewUser, Post) {
    var user = user
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
    var user = user
    if let list = user.posts {
        try await list.fetch()
        user.posts = List<Post>.init(elements: list.elements.filter { $0.id != post.id })
    }
    
    let savedUser = try await saveToDataStore(object: user)
    
    if let videos = post.videos {
        try await videos.fetch()
        for video in videos {
            let _ = try await deleteFromDataStore(object: video)
            try await removeVideoFromS3(email: user.email, videoId: video.id)
            // This removal will trigger a lambda function that removes the streams from the streams
            // bucket
        }
    }
    
    if let images = post.images {
        try await images.fetch()
        for image in images {
            let _ = try await deleteFromDataStore(object: image)
            try await removeImageFromS3(email: user.email, imageId: image.id)
        }
    }
    
    try await deleteFromDataStore(object: post)
    
    return savedUser
}

// Create UserSavedPost object to associate a post saved by a user
func userSavePost(user: NewUser, post: Post) async throws -> UserSavedPost {
    do {
        var user = user
        let userSavedPost = UserSavedPost(newuserID: user.id, postID: post.id)
        let savedPost = try await saveToDataStore(object: userSavedPost)
        
        if let list = user.savedPosts {
            try await list.fetch()
            user.savedPosts = List<UserSavedPost>.init(elements: list.elements + [userSavedPost])
        } else {
            user.savedPosts = List<UserSavedPost>.init(elements: [userSavedPost])
        }
        
        let _ = try await saveToDataStore(object: user)
        
        let newPost: Post
        if let list = post.usersSaving {
            try await list.fetch()
            let elems = list.elements + [userSavedPost]
            newPost = Post(from: post, usersSaving: elems)
        } else {
            newPost = Post(from: post, usersSaving: [userSavedPost])
        }
        
        let _ = try await saveToDataStore(object: newPost)
        
        return savedPost
    } catch {
        print("\(error)")
        throw error
    }
}

// Remove savedPost object and its associations with the user and post
func userUnsavePost(user: NewUser, post: Post, savedPost: UserSavedPost) async throws {
    var user = user
    if let list = user.savedPosts {
        try await list.fetch()
        user.savedPosts = List<UserSavedPost>.init(elements: list.elements.filter {
            $0.id != savedPost.id
        })
        
        let _ = try await saveToDataStore(object: user)
    }
    
    if let list = post.usersSaving {
        try await list.fetch()
        let elems = list.elements.filter { $0.id != savedPost.id }
        
        let newPost = Post(from: post, usersSaving: elems)
        let _ = try await saveToDataStore(object: newPost)
    }
    
    let _ = try await deleteFromDataStore(object: savedPost)
}

// Convenience function to abstract file path
func removeVideoFromS3(email: String, videoId: String) async throws {
    try await Amplify.Storage.remove(key: "videos/\(email)/\(videoId).mp4")
}

// Convenience function to abstract file path
func removeImageFromS3(email: String, imageId: String) async throws {
    try await Amplify.Storage.remove(key: "images/\(email)/\(imageId).jpg")
}

// Creates an empty text file for every reported post, saving by date and formatting each filename
// with reporting user, reported user, and reported post
func reportPost(currentUserId: String, reportedUserId: String, postId: String) async -> Bool {
    do {
        let key = "\(currentUserId),\(reportedUserId),\(postId).txt"
        
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd"
        let date = df.string(from: .now)
        
        let uploadTask = Amplify.Storage.uploadData(key: "reported-posts/\(date)/\(key)",
                                                    data: Data())
        let _ = try await uploadTask.value
        
        return true
    } catch {
        print("Failed to report post")
    }
    
    return false
}

// Tracks upload progress for up to maxWaitTimeSeconds before failing
// Note: numAttempts resets if there is at least one completion in the attempt. In other words,
// this function fails after (maxWaitTimeSeconds / sleepTimeSeconds) straight attempts without a
// successful upload
func trackUploadProgress(email: String, videos: [Video], completedUploads: Int = 0,
                         totalUploads: Int,
                         uploadingProgress: Binding<Double>,
                         numAttempts: Int = 0,
                         successfulUploads: Set<String> = [],
                         maxWaitTimeSeconds: Double) async throws -> Bool {
    let sleepTimeSeconds: Double = 2.0
    
    if numAttempts == Int(round(maxWaitTimeSeconds / sleepTimeSeconds)) {
        print("Failed after \(numAttempts) attempts")
        return false
    }
    var successes: Set<String> = Set()
    
    // Only run with videos that haven't succeeded yet
    for video in videos.filter({ !successfulUploads.contains($0.id) }) {
        // Checks that thumbnail can be loaded
        if let url = URL(string: getVideoThumbnailURL(email: email, videoId: video.id)),
           sendRequest(url: url),
           // Checks that one resolution can be streamed
           let streamURL = getStreamURL(email: email, videoId: video.id, resolution: .p360),
           isVideoStreamAvailable(stream: Stream(resolution: .p360, streamURL: streamURL)) {
            successes.insert(video.id)
        }
    }
    
    // Update completed runs to update progress bar
    let completedRunUploads = successes.count
    let totalCompletedUploads = completedUploads + completedRunUploads
    
    withAnimation(.spring) {
        uploadingProgress.wrappedValue = Double(totalCompletedUploads) / Double(totalUploads)
    }
    
    // Combines past successes and successes from this run
    successes = successes.union(successfulUploads)
    
    // If all video elements are in set of all successful uploads, then uploads are complete
    if Set(videos.map { $0.id }).subtracting(successes).isEmpty { return true }
    
    try await Task.sleep(seconds: sleepTimeSeconds)
    
    // Else, retry with videos that still need to succeed
    // Note: numAttempts resets after a successful upload
    return try await trackUploadProgress(email: email, videos: videos,
                                         completedUploads: totalCompletedUploads,
                                         totalUploads: totalUploads,
                                         uploadingProgress: uploadingProgress,
                                         numAttempts: completedRunUploads == 0 ? numAttempts + 1 : 0,
                                         successfulUploads: successes,
                                         maxWaitTimeSeconds: maxWaitTimeSeconds)
}

extension Post {
    // Add another initializer to easily update usersSaving through API call, but not accessible
    // outside this file
    fileprivate init(from: Post, usersSaving: [UserSavedPost]) {
        self.init(id: from.id,
                  caption: from.caption,
                  creationDate: from.creationDate,
                  images: from.images,
                  videos: from.videos,
                  newuserID: from.newuserID,
                  usersSaving: List<UserSavedPost>.init(elements: usersSaving),
                  isCoachesOnly: from.isCoachesOnly,
                  createdAt: from.createdAt,
                  updatedAt: from.updatedAt)
    }
}

extension Post: Equatable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}

struct PostsAPITestView: View {
    var email: String
    @State var currentUser: NewUser?
    
    var body: some View {
        VStack {
            Button {
                Task {
                    if let user = currentUser {
                        let post = Post(creationDate: .now(), newuserID: user.id,
                                        isCoachesOnly: false)
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
