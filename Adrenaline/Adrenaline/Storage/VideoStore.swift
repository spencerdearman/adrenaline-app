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
import AWSS3StoragePlugin

struct VideoItem {
    var key: String?
    var player: AVPlayer?
    
    var view: VideoPlayer<EmptyView> {
        VideoPlayer(player: player)
    }
    
    // Key is formatted as videos/email/videoName
    var email: String? {
        guard let key = key else { return nil }
        let comps = key.components(separatedBy: "/")
        if comps.count < 2 { return nil }
        return comps[1]
    }
    
    var name: String? {
        guard let key = key else { return nil }
        let comps = key.components(separatedBy: "/")
        if comps.count < 3 { return nil }
        return comps[2]
    }
}

// manage image cache and download
final class VideoStore {
    
    // our video cache
    private var videos: [String: VideoItem]
    private let placeholderName = "PLACEHOLDER"
    private let imageScale = 2
    
    // singleton (because of the cache)
    static var shared = VideoStore()
    
    init() {
        
        // initially empty cache
        videos = [:]
        
        // create a place holder image
        let player = AVPlayer()
        videos[self.placeholderName] = VideoItem(key: placeholderName, player: player)
    }
    
    // retrieve a video.
    // first check the cache, otherwise trigger an asynchronous download and return a placeholder
    func video(email: String, name: String) async -> VideoItem {
        var result : VideoItem
        let key = "\(email.lowercased())/\(name)"
        
        if let vid = videos[key] {
            
            print("Video \(key) found in cache")
            // return cached video when we have it
            result = vid
            
        } else {
            
            // trigger an asynchronous download
            let vid = await asyncDownloadVideo(email: email, name: name)
            result = vid
            
        }
        
        return result
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
                                 name: String) -> VideoItem {
        // Save video file locally
        guard let url = saveVideo(data: data, email: email, name: name) else {
            return self.placeholder()
        }
        
        let player = AVPlayer(url: url)
        let vid = VideoItem(key: "videos/\(email)/\(name)", player: player)
        
        // store video in cache
        addVideo(email: email, name: name, video: vid)
        
        return vid
    }
    
    // asynchronously download the video
    @MainActor // to be sure to execute the UI update on the main thread
    private func asyncDownloadVideo(email: String, name: String) async -> VideoItem {
        
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
    
    func uploadVideo(data: Data, email: String, name: String) async -> VideoItem? {
        let key = "\(email.lowercased())/\(name).mp4"
        print("Uploading video: \(key)")
        
        do {
            
            let task = Amplify.Storage.uploadData(key: "videos/\(key)", data: data)
            
            let _ = try await task.value
            print("Video \(key) uploaded")
            
            // Locally store video to avoid downloading from S3
            return localStoreVideo(data: data, email: email.lowercased(), name: name)
            
        } catch let error as StorageError {
            print("Cannot download video \(key): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading video \(key): \(error)")
        }
        
        return nil
    }
    
    func downloadVideosByEmail(email: String) async -> [VideoItem] {
        var result: [VideoItem] = []
        do {
            let options = StorageListRequest.Options(path: "videos/\(email)")
            let listResult = try await Amplify.Storage.list(options: options).items
            
            for item in listResult.sorted(by: {
                if let first = $0.lastModified, let second = $1.lastModified, first > second {
                    return true
                }
                
                return false
            }) {
                guard let name = item.key.components(separatedBy: "/").last else { continue }
                let key: String
                if name.suffix(4).starts(with: ".") {
                    key = String(name.dropLast(4))
                } else {
                    key = name
                }
                
                result.append(await self.video(email: email, name: key))
            }
            
            return result
        } catch {
            print("Failed to download videos by email")
        }
        
        return []
    }
    
    // Removes video from S3 storage and video cache
    func deleteVideo(email: String, name: String) async {
        let key = "videos/\(email.lowercased())/\(name).mp4"
        
        do {
            let _ = try await Amplify.Storage.remove(key: key)
            removeVideo(email: email, name: name)
        } catch {
            print("Failed to remove \(key)")
        }
    }
    
    // return the placeholder video from the cache
    func placeholder() -> VideoItem {
        if let vid = videos[self.placeholderName] {
            return vid
        } else {
            fatalError("Video cache is incorrectly initialized")
        }
    }
    
    // add video to the cache
    func addVideo(email: String, name: String, video: VideoItem) {
        videos["\(email.lowercased())/\(name)"] = video
    }
    
    // remove video from the cache
    func removeVideo(email: String, name: String) {
        videos.removeValue(forKey: "\(email.lowercased())/\(name)")
    }
}

