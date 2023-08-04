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
    
    func loadImage(_ url: URL) async throws -> UIImage? {
        let request = URLRequest(url: url)
        return try await fetch(request)
    }
    
    func loadImages(from urls: [URL]) async throws -> [URL: UIImage] {
        try await withThrowingTaskGroup(of: (URL, UIImage?).self) { group in
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
        print("Pulling \(url.absoluteString) from file system")
        do {
            let data = try Data(contentsOf: url)
            print("returning")
            return UIImage(data: data)
        } catch {
            print("Could not read data from URL")
        }
        
        return nil
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
    
    func fetch(_ urlRequest: URLRequest) async throws -> UIImage? {
        if let status = images[urlRequest] {
            switch status {
                case .fetched(let image):
                    print("fetcheed")
                    return image
                case .inProgress(let task):
                    print("in progress")
                    return try await task.value
            }
        } else {
            print("not in dictionary")
        }
        
        if let image = try self.imageFromFileSystem(for: urlRequest) {
            print("in file system")
            images[urlRequest] = .fetched(image)
            return image
        } else {
            print("not in file system")
        }
        
//        print("Pulling \(String(describing: urlRequest.url?.absoluteString)) from network")
        let task: Task<UIImage?, Error> = Task {
            let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
            guard let image = UIImage(data: imageData) else { return nil }
            try self.persistImage(image, for: urlRequest)
            return image
        }
        
        images[urlRequest] = .inProgress(task)
        
        guard let image = try await task.value else { return nil }
        
        images[urlRequest] = .fetched(image)
        
        return image
    }
    
    private func persistImage(_ image: UIImage, for urlRequest: URLRequest) throws {
        guard let url = fileName(for: urlRequest),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return
        }
        print("Persisting image \(String(describing: urlRequest.url?.absoluteString)) to disk")
        do {
            try data.write(to: url)
            print("succeeded")
        } catch {
            print("failed")
        }
    }
    
    private enum LoaderStatus {
        case inProgress(Task<UIImage?, Error>)
        case fetched(UIImage)
    }
}
