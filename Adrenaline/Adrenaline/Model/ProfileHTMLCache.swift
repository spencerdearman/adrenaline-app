//
//  ProfileHTMLCache.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import Foundation

class ProfileHTMLCache: Cache<String, String> {
    typealias K = String
    
    typealias V = String
    
    override var cacheName: String {
        get {
            return "profileHTML"
        }
        set {}
    }
    
    override func saveToDisk() {
        do {
            try super.saveToDisk()
            print("Successfully saved '\(cacheName + ".cache")' to disk")
        } catch {
            print("Failed to save '\(cacheName + ".cache")' to disk")
        }
    }
    
    // Needs to be copied and rewritten so decoder.decode can receive correct class
    func loadFromDisk() -> ProfileHTMLCache {
        do {
            return try super.loadFromDisk(instance: self) as! ProfileHTMLCache
        } catch {
            print("Failed to load '\(cacheName + ".cache")' from disk")
            return ProfileHTMLCache()
        }
    }
}
