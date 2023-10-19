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
        
        let player = AVPlayer()
        
        // create a place holder image
        videos[self.placeholderName] = VideoItem(key: placeholderName, player: player)
    }
    
    static func getCompressedFileURL(email: String, name: String) -> URL {
        let url = VideoStore.getVideoPathURL(email: email, name: name)
        
        let filename = url.deletingPathExtension().absoluteString + "-compressed.mp4"
        return URL(string: filename)!
    }
    
    static func getVideoPathURL(email: String, name: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = paths[0]
        
        let url = path.appendingPathComponent("\(email.lowercased())-\(name).mp4")
        
        return url
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
    
    func saveVideo(data: Data, email: String, name: String) async -> URL? {
        let url = VideoStore.getVideoPathURL(email: email, name: name)
        
        do {
            print("Saving video to URL: \(url.absoluteString)")
            
            try data.write(to: url)
            
            let compressor = CompressVideo()
            try await compressor.compressFile(url) { (compressedURL) in
                print("Compressed video to URL: \(compressedURL)")
            }
            
            return url
        } catch {
            print("Failed to write data to URL")
        }
        
        return nil
    }
    
    private func localStoreVideo(data: Data, email: String,
                                 name: String) async -> VideoItem {
        // Save video file locally
        guard let url = await saveVideo(data: data, email: email, name: name) else {
            return self.placeholder()
        }
        
        let player = AVPlayer(url: url)
        let vid = VideoItem(key: "videos/\(email)/\(name)", player: player)
        
        // store video in cache
        addVideo(email: email, name: name, video: vid)
        
        return vid
    }
    
    // asynchronously download the video
    private func asyncDownloadVideo(email: String, name: String) async -> VideoItem {
        
        // trigger asynchronous download
        let task = Task {
            // download the video from our API
            let data = await downloadVideo(email: email, name: name)
            
            return await localStoreVideo(data: data, email: email, name: name)
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
            return await localStoreVideo(data: data, email: email.lowercased(), name: name)
            
        } catch let error as StorageError {
            print("Cannot download video \(key): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading video \(key): \(error)")
        }
        
        return nil
    }
    
    // Gets all of the S3 storage items to download for a given email, sorted
    // descending by lastModified
    func getVideoItemsByEmail(email: String) async -> [StorageListResult.Item]? {
        do{
            let options = StorageListRequest.Options(path: "videos/\(email)")
            let listResult = try await Amplify.Storage.list(options: options).items
            
            return listResult.sorted(by: {
                if let first = $0.lastModified, let second = $1.lastModified, first > second {
                    return true
                }
                
                return false
            })
        } catch {
            print("Failed to get VideoItems from S3")
        }
        
        return nil
    }
    
    // Downloads an individual item from S3 and returns it; can be used in tandem with
    // getVideoItemsByEmail() to get the list of items beforehand and get results as they finish
    func downloadVideoItem(item: StorageListResult.Item, email: String) async -> VideoItem? {
        guard let name = item.key.components(separatedBy: "/").last else { return nil }
        let key: String
        if name.suffix(4).starts(with: ".") {
            key = String(name.dropLast(4))
        } else {
            key = name
        }
        
        return await self.video(email: email, name: key)
    }
    
    // Gets all videos from S3 for the given email
    func downloadVideosByEmail(email: String) async -> [VideoItem] {
        var result: [VideoItem] = []
        
        guard let listItems = await getVideoItemsByEmail(email: email) else { return [] }
        
        for item in listItems {
            if let video = await downloadVideoItem(item: item, email: email) {
                result.append(video)
            }
        }
        
        return result
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
    func addVideo(email: String, name: String, video : VideoItem) {
        videos["\(email.lowercased())/\(name)"] = video
    }
    
    // remove video from the cache
    func removeVideo(email: String, name: String) {
        videos.removeValue(forKey: "\(email.lowercased())/\(name)")
    }
}


