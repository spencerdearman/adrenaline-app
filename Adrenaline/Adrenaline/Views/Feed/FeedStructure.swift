//
//  FeedStructure.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import UIKit
import AVKit


// FeedItems should not be initialized, only used for inheritance
class FeedItem: Identifiable {
    var id: String = UUID().uuidString
    var isExpanded: Bool = false
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
}

class MeetFeedItem: FeedItem {
    var meet: MeetEvent
    
    init(meet: MeetEvent, namespace: Namespace.ID) {
        self.meet = meet
        super.init()
        self.collapsedView = MeetFeedItemCollapsedView(id: self.id, namespace: namespace,
                                                       meet: self.meet)
        self.expandedView = MeetFeedItemExpandedView(id: self.id, namespace: namespace,
                                                     meet: self.meet)
    }
}

struct MeetFeedItemCollapsedView: View {
    var id: String
    var namespace: Namespace.ID
    var meet: MeetEvent
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(40)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15), radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            Text(meet.name)
                .font(.subheadline)
                .matchedGeometryEffect(id: "body" + id, in: namespace)
        }
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.25)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct MeetFeedItemExpandedView: View {
    var id: String
    var namespace: Namespace.ID
    var meet: MeetEvent
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(40)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15), radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            VStack {
                Text(meet.name)
                    .font(.title)
                Text(meet.link ?? "")
            }
            .matchedGeometryEffect(id: "body" + id, in: namespace)
        }
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.5)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

enum Media {
    case video(VideoPlayer<EmptyView>)
    case text(String)
//    case profile(Profi)
}

class MediaFeedItem: FeedItem {
    var media: Media
    
    init(media: Media, namespace: Namespace.ID) {
        self.media = media
        super.init()
        self.collapsedView = MediaFeedItemCollapsedView(id: self.id, namespace: namespace,
                                                        media: media)
        self.expandedView = MediaFeedItemExpandedView(id: self.id, namespace: namespace,
                                                       media: media)
    }
}

struct MediaFeedItemCollapsedView: View {
    var id: String
    var namespace: Namespace.ID
    var media: Media
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(40)
                .shadow(radius: 10)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            Text(id.prefix(10))
                .font(.subheadline)
                .matchedGeometryEffect(id: "title" + id, in: namespace)
        }
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.25)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct MediaFeedItemExpandedView: View {
    var id: String
    var namespace: Namespace.ID
    var media: Media
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var isVideo: Bool {
        if case .video(_) = media {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(40)
                .shadow(radius: 10)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            VStack {
                Text(id.prefix(10))
                    .font(.title)
                    .matchedGeometryEffect(id: "title" + id, in: namespace)
                if case .video(let videoPlayer) = media {
                    videoPlayer
                        .padding()
                        .matchedGeometryEffect(id: "body" + id, in: namespace)
                } else if case .text(let string) = media {
                    Text(string)
                        .matchedGeometryEffect(id: "body" + id, in: namespace)
                }
            }
        }
        .frame(width: screenWidth * 0.9, height: isVideo
               ? screenHeight * 0.55
               : screenWidth * 0.5)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

class SuggestedFeedItem: FeedItem {
    var suggested: String
    
    init(suggested: String, collapsed: @escaping () -> any View,
         expanded: @escaping () -> any View) {
        self.suggested = suggested
        super.init()
    }
}
