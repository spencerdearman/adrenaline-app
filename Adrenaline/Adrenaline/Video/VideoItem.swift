//
//  VideoItem.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/20/23.
//  https://github.com/create-with-swift/streaming-with-swiftui/blob/main/StreamingApp/Video.swift
//

import SwiftUI
import Network


struct VideoItem {
    let name: String
    let streams: [Stream]
    var thumbnailURL: String
    var isVertical: Bool
    
    // Key is formatted as videos/email/videoName
    var email: String? {
        let comps = name.components(separatedBy: "/")
        if comps.count < 2 { return nil }
        return comps[1]
    }
    
    init() {
        self.name = ""
        self.streams = []
        self.thumbnailURL = ""
        self.isVertical = false
    }
    
    init(email: String, videoId: String) {
        self.name = "videos/\(email)/\(videoId)"
        var streams: [Stream] = []
        let videoUrlHead = getVideoHLSUrlKey(email: email, videoId: videoId)
        
//        for res in Resolution.allCases {
//            if let url = URL(string: "\(videoUrlHead).m3u8") {
//                streams.append(Stream(resolution: res, streamURL: url))
//            } else {
//                print("Failed to get url for resolution \(res.displayValue)")
//            }
//        }
        if let url = URL(string: "\(videoUrlHead).m3u8") {
            streams.append(Stream(resolution: .p1080, streamURL: url))
        } else {
            print("Failed to get url for resolution \(Resolution.p1080.displayValue)")
        }
        
        self.streams = streams
        self.thumbnailURL = getVideoThumbnailURL(email: email, videoId: videoId)
        self.isVertical = isVerticalImage(url: self.thumbnailURL)
    }
}

struct Stream {
    let resolution: Resolution
    let streamURL: URL
}

enum Resolution: Int, Identifiable, Comparable, CaseIterable {
    case p360 = 0
    case p540
    case p720
    case p1080
    
    var id: Int { rawValue }
    
    var displayValue: String {
        switch self {
            case .p360: return "360p"
            case .p540: return "540p"
            case .p720: return "720p"
            case .p1080: return "1080p"
        }
    }
    
    static func ==(lhs: Resolution, rhs: Resolution) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    static func <(lhs: Resolution, rhs: Resolution) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
