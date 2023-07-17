//
//  ProfileMeetCache.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/27/23.
//

import Foundation

class ProfileMeetCache: Cache<String, [[String]]> {
    typealias K = String
    
    typealias V = [[String]]
    
    override var cacheName: String {
        get {
            return "profileMeets"
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
    func loadFromDisk() -> ProfileMeetCache {
        do {
            return try super.loadFromDisk(instance: self) as! ProfileMeetCache
        } catch {
            print("Failed to load '\(cacheName + ".cache")' from disk")
            return ProfileMeetCache()
        }
    }
}
