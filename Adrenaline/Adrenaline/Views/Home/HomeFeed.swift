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

struct HomeFeed_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeed()
    }
}
