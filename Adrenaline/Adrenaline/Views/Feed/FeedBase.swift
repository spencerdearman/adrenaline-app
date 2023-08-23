//
//  FeedBase.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import UIKit
import AVKit


struct FeedBase: View {
    @Environment(\.colorScheme) var currentMode
    @State private var feedItems: [FeedItem] = []
    @State private var tabBarState: Visibility = .visible
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @Namespace var namespace
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
                .opacity(0.9)
                .scaleEffect(1.1)
            
            // Top Menu Bar
            // Will become .overlay later
            HStack {
                // Adrenaline Title
                Text("Adrenaline")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
                SearchButton()
                ProfileButton(imageName: "Spencer")
            }
            .frame(width: screenWidth * 0.87)
            .offset(y: -screenHeight * 0.4)
            
            
            HideTabBarScrollView(tabBarState: $tabBarState) {
                VStack(spacing: -18) {
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
            .offset(y: screenHeight * 0.09)
            .onAppear {
                feedItems = [
                    MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                                 namespace: namespace),
                    MediaFeedItem(media: Media.text("Hello World"), namespace: namespace),
                    MediaFeedItem(media: Media.video(VideoPlayer(player: nil)), namespace: namespace)
                ]
            }
//            Rectangle()
//            .foregroundColor(.clear)
//            .frame(width: 350, height: 450)
//            .background(.white.opacity(0.9))
//            .cornerRadius(30)
//            .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15), radius: 15, x: 0, y: 30)
        }
    }
}

struct FeedBase_Previews: PreviewProvider {
    static var previews: some View {
        FeedBase()
    }
}
