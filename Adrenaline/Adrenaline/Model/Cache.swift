//
//  Cache.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/27/23.
//  Borrowed from https://www.swiftbysundell.com/articles/caching-in-swift/.
//

import Foundation

typealias Key = Hashable & Codable
typealias Value = Codable
enum CustomCache {
    case profileMeets(ProfileMeetCache)
    case profileHTML(ProfileHTMLCache)
    
    func clearCacheFromDisk() throws {
        switch self {
            case .profileMeets (let cache):
                try cache.clearCacheFromDisk()
            case .profileHTML (let cache):
                try cache.clearCacheFromDisk()
        }
    }
    
    subscript(key: any Key) -> (any Value)? {
        get {
            switch self {
                case .profileMeets (let cache):
                    return cache[key as! String]
                case .profileHTML (let cache):
                    return cache[key as! String]
            }
        }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                switch self {
                    case .profileMeets (let cache):
                        cache.removeValue(forKey: key as! String)
                        return
                    case .profileHTML (let cache):
                        cache.removeValue(forKey: key as! String)
                        return
                }
            }
            
            switch self {
                case .profileMeets (let cache):
                    cache.insert(value as! [[String]], forKey: key as! String)
                case .profileHTML (let cache):
                    cache.insert(value as! String, forKey: key as! String)
            }
        }
    }
}

fileprivate var emptyGlobalCaches: [String: CustomCache] = [
    "profileMeets": CustomCache.profileMeets(ProfileMeetCache()),
    "profileHTML": CustomCache.profileHTML(ProfileHTMLCache())
]

// Access from any file using 'GlobalCaches.caches[<cacheKey>]
struct GlobalCaches {
    // Internal caches dict, should not be referenced except through subscripting
    //  e.g. GlobalCaches.caches["profileMeetCache"]["2023]
    static var caches: [String: CustomCache] = emptyGlobalCaches
    
    static func saveAllCaches() {
        for (_, cache) in caches {
            if case let .profileMeets(c) = cache {
                c.saveToDisk()
            }
        }
    }
    
    static func loadAllCaches() {
        for (key, cache) in caches {
            if case let .profileMeets(c) = cache {
                caches[key] = CustomCache.profileMeets(c.loadFromDisk())
            } else if case let .profileHTML(c) = cache {
                caches[key] = CustomCache.profileHTML(c.loadFromDisk());
            }
        }
    }
    
    static func clearAllCachesFromDisk() {
        for (key, cache) in caches {
            do {
                try cache.clearCacheFromDisk()
            } catch {
                print("Cache key \(key) failed to be cleared from disk")
            }
        }
        caches = emptyGlobalCaches
    }
}

class Cache<Key: Hashable & Codable, Value: Codable>: Codable {
    private var wrapped = NSCache<WrappedKey, Entry>()
    private var dateProvider: () -> Date
    private var entryLifetime: TimeInterval
    private var keyTracker = KeyTracker()
    var cacheName: String = "default"
    
    init(dateProvider: @escaping () -> Date = Date.init,
         entryLifetime: TimeInterval = 12 * 60 * 60, // 12hr timeout
         maximumEntryCount: Int = 50) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
        wrapped.countLimit = maximumEntryCount
        wrapped.delegate = keyTracker
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
    
    func insert(_ value: Value, forKey key: Key) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
    }
    
    func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            // Discard values that have expired
            removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
    
    func saveToDisk() throws {
        let fileManager: FileManager = .default
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(cacheName + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }
    
    func loadFromDisk(instance: Cache = Cache()) throws -> Cache<Key, Value> {
        let fileManager: FileManager = .default
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(cacheName + ".cache")
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: fileURL)
        let cacheObject = try decoder.decode(type(of: instance),
                                             from: data)
        print("Successfully loaded '\(cacheName + ".cache")' from disk")
        return cacheObject
    }
    
    func clearCacheFromDisk() throws {
        let fileManager: FileManager = .default
        let folderURLs = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )
        
        let fileURL = folderURLs[0].appendingPathComponent(cacheName + ".cache")
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("Successfully removed '\(cacheName + ".cache")' from disk")
            } catch {
                print("Failed to remove '\(cacheName + ".cache")' from disk")
            }
        } else {
            print("Cache file '\(cacheName + ".cache")' does not exist")
        }
    }
}

extension Cache {
    final class WrappedKey: NSObject {
        let key: Key
        
        init(_ key: Key) { self.key = key }
        
        override var hash: Int { return key.hashValue }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            
            return value.key == key
        }
    }
    
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date
        
        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
    
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }
        
        return entry
    }
    
    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
    
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        
        func cache(_ cache: NSCache<AnyObject, AnyObject>,
                   willEvictObject object: Any) {
            guard let entry = object as? Entry else {
                return
            }
            
            keys.remove(entry.key)
        }
    }
    
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }
            
            insert(value, forKey: key)
        }
    }
}

extension Cache.Entry: Codable where Key: Codable, Value: Codable {}
