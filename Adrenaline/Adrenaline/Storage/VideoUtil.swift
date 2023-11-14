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
func getVideoHLSUrlKey(email: String, videoId: String) -> String {
    return CLOUDFRONT_STREAM_BASE_URL + "\(email.replacingOccurrences(of: "@", with: "%40"))/\(videoId)/output/HLS/\(videoId)"
}

// Returns the full URL minus the "_{RESOLUTION}.m3u8" suffix
func getVideoThumbnailUrl(email: String, videoId: String) -> String {
    return CLOUDFRONT_STREAM_BASE_URL + "\(email.replacingOccurrences(of: "@", with: "%40"))/\(videoId)/output/Thumbnails/\(videoId).0000000.jpg"
}

// Returns the full URL for the thumbnail of a video
func getVideoThumbnailURL(email: String, videoId: String) -> String {
    return CLOUDFRONT_STREAM_BASE_URL + "\(email.replacingOccurrences(of: "@", with: "%40"))/\(videoId)/output/Thumbnails/\(videoId).0000000.jpg"
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

func uploadVideo(data: Data, email: String, name: String) async throws {
    let key = "videos/\(email.lowercased())/\(name).mp4"
    print("Uploading video: \(key)")

    // Set task to initially use normal video file
    var task = Amplify.Storage.uploadData(key: key, data: data)
    
    // Check if compressed version exists, if yes, reassign task var to upload compressed video
    let compressedFileURL = getCompressedFileURL(email: email, name: name)
    print("Compressed URL to upload: \(compressedFileURL)")
    if FileManager.default.fileExists(atPath: compressedFileURL.path) {
        print("Compressed file exists")
        if let compressedData = NSData(contentsOfFile: compressedFileURL.path) {
            print("Uploading compressed data...")
            task = Amplify.Storage.uploadData(key: key,
                                              data: compressedData as Data)
        } else {
            print("Failed to get compressed data")
        }
    }
    print("Assigned storage task...")
        
    let _ = try await task.value
    print("Video \(name) uploaded")
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

// https://medium.com/geekculture/find-image-dimensions-from-url-in-ios-swift-a186297e9922
func isVerticalImage(url: String) -> Bool {
    if let imageSource = CGImageSourceCreateWithURL(URL(string: url)! as CFURL, nil) {
        if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as
            Dictionary? {
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! Int
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! Int
            return pixelWidth < pixelHeight
        }
    }
    
    return false
}

// https://stackoverflow.com/a/64701285/22068672
func getVideoResolution(url: String) -> CGSize? {
    guard let track = AVURLAsset(url: URL(string: url)!).tracks(withMediaType: AVMediaType.video).first else { return nil }
    let size = track.naturalSize.applying(track.preferredTransform)
    return size
}

func isVerticalLocalVideo(url: String) -> Bool {
    if let size = getVideoResolution(url: url) {
        return size.width < size.height
    }
    
    return false
}
