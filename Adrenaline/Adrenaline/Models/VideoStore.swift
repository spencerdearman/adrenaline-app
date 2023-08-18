//
//  VideoStore.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/17/23.
//

import Foundation
import SwiftUI
import Amplify
import AVKit

// manage image cache and download
final class VideoStore {
    
    // our video cache
    private var videos: [String: VideoPlayer<EmptyView>]
    private let placeholderName = "PLACEHOLDER"
    private let imageScale = 2
    
    // singleton (because of the cache)
    static var shared = VideoStore()
    
    init() {
        
        // initially empty cache
        videos = [:]
        
        // create a place holder image
        videos[self.placeholderName] = VideoPlayer(player: AVPlayer())
    }
    
    // retrieve a video.
    // first check the cache, otherwise trigger an asynchronous download and return a placeholder
    func video(email: String, name: String) async -> VideoPlayer<EmptyView> {
        var result : VideoPlayer<EmptyView>?
        let key = "\(email.lowercased())/\(name)"
        
        if let vid = videos[key] {
            
            print("Video \(key) found in cache")
            // return cached video when we have it
            result = vid
            
        } else {
            
            // trigger an asynchronous download
            let vid = await asyncDownloadVideo(email: email, name: name)
            print("video found")
            result = vid
            
        }
        return result!
    }
    
    private func saveVideo(data: Data, email: String, name: String) -> URL? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = paths[0]
        
        // Use - instead of / to avoid path issues
        let url = path.appendingPathComponent("\(email.lowercased())-\(name).mp4")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to write data to URL")
        }
        
        return nil
    }
    
    private func localStoreVideo(data: Data, email: String,
                                 name: String) -> VideoPlayer<EmptyView> {
        // Save video file locally
        guard let url = saveVideo(data: data, email: email, name: name) else {
            return self.placeholder()
        }
        
        print("url works")
        let player = AVPlayer(url: url)
        let vid = VideoPlayer(player: player)
        
        // store video in cache
        addVideo(email: email, name: name, video: vid)
        
        return vid
    }
    
    // asynchronously download the video
    @MainActor // to be sure to execute the UI update on the main thread
    private func asyncDownloadVideo(email: String, name: String) async -> VideoPlayer<EmptyView> {
        
        // trigger asynchronous download
        let task = Task {
            // download the video from our API
            let data = await downloadVideo(email: email, name: name)
            
            return localStoreVideo(data: data, email: email, name: name)
        }
        
        return await task.value
    }
    
    func downloadVideo(email: String, name: String) async -> Data {
        let key = "\(email.lowercased())/\(name).mp4"
        print("Downloading video: \(key)")
        
        do {
            
            let task = Amplify.Storage.downloadData(key: "videos/\(key)")
            let data = try await task.value
            print("Video \(key) downloaded")
            
            return data
            
        } catch let error as StorageError {
            print("Cannot download video \(key): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading video \(key): \(error)")
        }
        return Data() // could return a default video
    }
    
    func uploadVideo(data: Data, email: String, name: String) async -> VideoPlayer<EmptyView>? {
        let key = "\(email.lowercased())/\(name).mp4"
        print("Uploading video: \(key)")
        
        do {
            
            let task = Amplify.Storage.uploadData(key: "videos/\(key)", data: data)
            //            Task {
            //                for await progress in await task.progress {
            //                    print("Progress: \(progress)")
            //                }
            //            }
            
            let _ = try await task.value
            print("Video \(key) uploaded")
            //            print(value)
            
            // Locally store video to avoid downloading from S3
            return localStoreVideo(data: data, email: email.lowercased(), name: name)
            
        } catch let error as StorageError {
            print("Cannot download video \(key): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading video \(key): \(error)")
        }
        
        return nil
    }
    
    // return the placeholder video from the cache
    func placeholder() -> VideoPlayer<EmptyView> {
        if let vid = videos[self.placeholderName] {
            return vid
        } else {
            fatalError("Video cache is incorrectly initialized")
        }
    }
    
    // add video to the cache
    func addVideo(email: String, name: String, video : VideoPlayer<EmptyView>) {
        videos["\(email.lowercased())/\(name)"] = video
    }
}


