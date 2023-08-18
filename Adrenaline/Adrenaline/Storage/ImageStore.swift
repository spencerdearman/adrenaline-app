//
//  ImageStore.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/16/23.
//

import Foundation
import SwiftUI
import Amplify

// allow to create image with uniform color
// https://gist.github.com/isoiphone/031da3656d69c0d85805
extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// Create an image from Data :
// Data -> UIImage -> Image
extension Image {
    init(fromData data:Data, scale: Int, name:String) {
        guard let uiImage = UIImage(data: data) else {
            fatalError("Couldn't convert image data \(name)")
        }
        self = Image(uiImage.cgImage!, scale: CGFloat(scale), label: Text(verbatim: name))
        
    }
}

// manage image cache and download
final class ImageStore {
    
    // our image cache
    private var images: [String: Image]
    private let placeholderName = "PLACEHOLDER"
    private let imageScale = 2
    
    // singleton (because of the cache)
    static var shared = ImageStore()
    
    init() {
        
        // initially empty cache
        images = [:]
        
        // create a place holder image
        images[self.placeholderName] = Image(uiImage: UIImage.imageWithColor(color: UIColor.lightGray, size: CGSize(width:300, height: 300)))
    }
    
    // retrieve an image.
    // first check the cache, otherwise trigger an asynchronous download and return a placeholder
    func image(name: String) async -> Image {
        print("called")
        var result : Image?
        
        if let img = images[name] {
            
            print("Image \(name) found in cache")
            // return cached image when we have it
            result = img
            
        } else {
            
            // trigger an asynchronous download
            // result will be store in landmark.image and that will trigger an UI refresh
            let img = await asyncDownloadImage(name)
//            guard let img = images[name] else { return self.placeholder() }
            print("image found")
            result = img
            
//            // and return a placeholder while waiting for the result
//            result = self.placeholder()
            
        }
        return result!
    }
    
    // asynchronously download the image
    @MainActor // to be sure to execute the UI update on the main thread
    private func asyncDownloadImage(_ name: String) async -> Image {
        
        // trigger asynchronous download
        let task = Task {
            // download the image from our API
            let data = await downloadImage(name)
            
            // convert to an image : Data -> UIImage -> Image
            let img = Image(fromData: data, scale: imageScale, name: name)
            
            // store image in cache
            addImage(name: name, image: img)
            
            return img
        }
        
        return await task.value
    }
    
    func downloadImage(_ name: String) async -> Data {
        print("Downloading image : \(name)")
        
        do {
            
            let task = Amplify.Storage.downloadData(key: "\(name).jpg")
            let data = try await task.value
            print("Image \(name) downloaded")
            
            return data
            
        } catch let error as StorageError {
            print("Can not download image \(name): \(error.errorDescription). \(error.recoverySuggestion)")
        } catch {
            print("Unknown error when loading image \(name): \(error)")
        }
        return Data() // could return a default image
    }
    
    // return the placeholder image from the cache
    func placeholder() -> Image {
        if let img = images[self.placeholderName] {
            return img
        } else {
            fatalError("Image cache is incorrectly initialized")
        }
    }
    
    // add image to the cache
    func addImage(name: String, image : Image) {
        images[name] = image
    }
}

