//
//  VideoUtil.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/17/23.
//

import Foundation
import SwiftUI
import Amplify
import AVKit
import AWSS3StoragePlugin


func getCompressedFileURL(email: String, name: String) -> URL {
    let url = getVideoPathURL(email: email, name: name)
    
    let filename = url.deletingPathExtension().absoluteString + "-compressed.mp4"
    return URL(string: filename)!
}

func getVideoPathURL(email: String, name: String) -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let path = paths[0]
    
    let url = path.appendingPathComponent("\(email.lowercased())-\(name).mp4")
    
    return url
}

// Returns the full URL minus the "_{RESOLUTION}.m3u8" suffix
func getVideoUrlKey(email: String, videoId: String) -> String {
    return CLOUDFRONT_BASE_URL + "\(email.replacingOccurrences(of: "@", with: "%40"))/\(videoId)/output/HLS/\(videoId)"
}

// Returns the full URL for the thumbnail of a video
func getVideoThumbnailURL(email: String, videoId: String) -> String {
    return CLOUDFRONT_BASE_URL + "\(email.replacingOccurrences(of: "@", with: "%40"))/\(videoId)/output/Thumbnails/\(videoId).0000000.jpg"
}

func saveVideo(data: Data, email: String, name: String) async -> URL? {
    let url = getVideoPathURL(email: email, name: name)
    
    do {
        print("Saving video to URL: \(url.absoluteString)")
        
        try data.write(to: url)
        
        let compressor = await CompressVideo()
        try await compressor.compressFile(url) { (compressedURL) in
            print("Compressed video to URL: \(compressedURL)")
        }
        
        return url
    } catch {
        print("Failed to write data to URL")
    }
    
    return nil
}

func uploadVideo(data: Data, email: String, name: String) async {
    let key = "\(email.lowercased())/\(name).mp4"
    print("Uploading video: \(key)")
    
    do {
        
        let task = Amplify.Storage.uploadData(key: "videos/\(key)", data: data)
        
        let _ = try await task.value
        print("Video \(key) uploaded")
        
    } catch let error as StorageError {
        print("Cannot download video \(key): \(error.errorDescription). \(error.recoverySuggestion)")
    } catch {
        print("Unknown error when loading video \(key): \(error)")
    }
}

// Gets all of the S3 storage items to download for a given email, sorted
// descending by lastModified
func getVideosByEmail(email: String) async -> [VideoPlayerViewModel]? {
    do{
        let options = StorageListRequest.Options(path: "videos/\(email)")
        let listResult = try await Amplify.Storage.list(options: options).items
        
        let sorted = listResult.sorted(by: {
            if let first = $0.lastModified, let second = $1.lastModified, first > second {
                return true
            }
            
            return false
        })
        
        return sorted.map {
            print($0.key)
            // Remove extension from key name
            guard let basename = $0.key.split(separator: "/").last else { return VideoPlayerViewModel(video: VideoItem(), initialResolution: .p540) }
            let videoId = String(basename.dropLast(4))
            return VideoPlayerViewModel(video: VideoItem(email: email, videoId: videoId), initialResolution: .p540)
        }
    } catch {
        print("Failed to get VideoItems from S3")
    }
    
    return nil
}

func imageFromVideo(url: URL, at time: TimeInterval) async throws -> Image {
    return try await imageFromVideoBackground(url: url, at: time)
}

// Call from background queue
func imageFromVideoBackground(url: URL, at time: TimeInterval) async throws -> Image {
    let asset = AVURLAsset(url: url)
    
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.appliesPreferredTrackTransform = true
    assetImageGenerator.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
    
    let cmTime = CMTime(seconds: time, preferredTimescale: 60)
    let thumbnailImage = try await assetImageGenerator.image(at: cmTime).image
    return Image(uiImage: UIImage(cgImage: thumbnailImage))
}
