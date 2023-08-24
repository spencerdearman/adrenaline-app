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
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    @Environment(\.colorScheme) var currentMode
    @State var feedModel: FeedModel = FeedModel()
    @State var showDetail: Bool = false
    @State var showTab: Bool = true
    @State var showNav: Bool = true
    @State var show = false
    @State var showStatusBar = true
    @State var showCourse = false
    @State var contentHasScrolled = false
    @State private var feedItems: [FeedItem] = []
    @State private var tabBarState: Visibility = .visible
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @Namespace var namespace
    var body: some View {
        ZStack {
            Custom.darkGray.ignoresSafeArea()
            Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
            
            if feedModel.showTile {
                detail
            }
            
            ScrollView {
                // Detects Movement of Page
                scrollDetection
                
                Rectangle()
                    .frame(width: 100, height: 150)
                    .opacity(0)
                
                if showDetail {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach($feedItems) { _ in
                            Rectangle()
                                .fill(.white)
                                .cornerRadius(30)
                                .shadow(radius: 20)
                                .opacity(0.3)
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        item.frame(height: 200)
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                }
            }
            .coordinateSpace(name: "scroll")
        }
        .onAppear {
            feedItems = [
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.text("Hello World"), namespace: namespace),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)), namespace: namespace)
            ]
        }
        
        .onChange(of: feedModel.showTile) { value in
            withAnimation {
                feedModel.showTab.toggle()
                showNav.toggle()
                showStatusBar.toggle()
            }
        }
        .overlay{
            if feedModel.showTab {
                NavigationBar(title: "Adrenaline", contentHasScrolled: $contentHasScrolled, feedModel: $feedModel)
                    .frame(width: screenWidth)
            }
        }
        .statusBar(hidden: !showStatusBar)
    }
    
    var item: some View {
        ForEach($feedItems) { item in
                AnyView(item.collapsedView.wrappedValue)
        }
    }
    
    var detail: some View {
        ForEach($feedItems) { item in
            if item.id == feedModel.selectedItem {
                AnyView(item.expandedView.wrappedValue)
            }
        }
    }
    
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut) {
                if value < 0 {
                    contentHasScrolled = true
                    tabBarState = .hidden
                } else {
                    contentHasScrolled = false
                    tabBarState = .visible
                }
            }
        }
    }
}

struct FeedBase_Previews: PreviewProvider {
    static var previews: some View {
        FeedBase()
    }
}
