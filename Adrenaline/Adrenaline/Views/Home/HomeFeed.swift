//
//  HomeFeed.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/22/23.
//

import SwiftUI
import UIKit
import AVKit

struct HomeFeed: View {
    @State private var feedItems: [FeedItem] = []
    @State private var tabBarState: Visibility = .visible
    @Namespace var namespace
    
    var body: some View {
        HideTabBarScrollView(tabBarState: $tabBarState) {
            VStack(spacing: 0) {
                ForEach($feedItems) { item in
                    Group {
                        if item.isExpanded.wrappedValue {
                            AnyView(item.expandedView.wrappedValue)
                        } else {
                            AnyView(item.collapsedView.wrappedValue)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            item.isExpanded.wrappedValue.toggle()
                        }
                    }
                }
            }
        }
        .onAppear {
            feedItems = [
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace),
                MediaFeedItem(media: Media.text("Hello World"), namespace: namespace),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)), namespace: namespace)
            ]
        }
    }
}

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
                .shadow(radius: 10)
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
                .shadow(radius: 10)
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

struct HomeFeed_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeed()
    }
}
