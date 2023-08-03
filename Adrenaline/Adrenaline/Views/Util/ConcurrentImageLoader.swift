//
//  ConcurrentImageLoader.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/3/23.
//  https://www.donnywals.com/using-swifts-async-await-to-build-an-image-loader/
//  https://www.swiftbysundell.com/articles/swift-concurrency-multiple-tasks-in-parallel/
//

import SwiftUI
import Foundation

final class ConcurrentImageLoader {
    private var images: [URLRequest: LoaderStatus] = [:]
    
    func loadImage(_ url: URL) async throws -> UIImage {
        let request = URLRequest(url: url)
        return try await fetch(request)
    }
    
    func loadImages(from urls: [URL]) async throws -> [URL: UIImage] {
        try await withThrowingTaskGroup(of: (URL, UIImage).self) { group in
            for url in urls {
                group.addTask {
                    let image = try await self.loadImage(url)
                    return (url, image)
                }
            }
            
            var images = [URL: UIImage]()
            
            for try await (url, image) in group {
                images[url] = image
            }
            
            return images
        }
    }
    
    private func imageFromFileSystem(for urlRequest: URLRequest) throws -> UIImage? {
        guard let url = fileName(for: urlRequest) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return nil
        }
        
        let data = try Data(contentsOf: url)
        return UIImage(data: data)
    }
    
    private func fileName(for urlRequest: URLRequest) -> URL? {
        guard let fileName = urlRequest.url?.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                in: .userDomainMask).first else {
            return nil
        }
        
        return applicationSupport.appendingPathComponent(fileName)
    }
    
    func fetch(_ urlRequest: URLRequest) async throws -> UIImage {
        if let status = images[urlRequest] {
            switch status {
                case .fetched(let image):
                    return image
                case .inProgress(let task):
                    return try await task.value
            }
        }
        
        if let image = try self.imageFromFileSystem(for: urlRequest) {
            images[urlRequest] = .fetched(image)
            return image
        }
        
        let task: Task<UIImage, Error> = Task {
            let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
            let image = UIImage(data: imageData)!
            try self.persistImage(image, for: urlRequest)
            return image
        }
        
        images[urlRequest] = .inProgress(task)
        
        let image = try await task.value
        
        images[urlRequest] = .fetched(image)
        
        return image
    }
    
    private func persistImage(_ image: UIImage, for urlRequest: URLRequest) throws {
        guard let url = fileName(for: urlRequest),
              let data = image.jpegData(compressionQuality: 0.8) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return
        }
        
        try data.write(to: url)
    }
    
    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(UIImage)
    }
}
