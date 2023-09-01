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
    @Namespace var namespace
    @Binding var diveMeetsID: String
    @Binding var showAccount: Bool
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
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        ZStack {
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
            
            if feedModel.showTile {
                ForEach($feedItems) { item in
                    if item.id == feedModel.selectedItem {
                        AnyView(item.expandedView.wrappedValue)
                    }
                }
            }
            
            ScrollView {
                // Scrolling Detection
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
                
                Rectangle()
                    .frame(width: 100, height: screenHeight * 0.15)
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
                    .offset(y: -100)
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach($feedItems) { item in
                                AnyView(item.collapsedView.wrappedValue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                }
            }
            .dynamicTypeSize(.xSmall ... .xxLarge)
            .coordinateSpace(name: "scroll")
        }
        .onAppear {
            feedItems = [
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                ImageFeedItem(image: Image("Spencer"), namespace: namespace, feedModel: $feedModel),
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                ImageFeedItem(image: Image("Logan"), namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)),
                              namespace: namespace, feedModel: $feedModel),
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                ImageFeedItem(image: Image("Beck"), namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)),
                              namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)),
                              namespace: namespace, feedModel: $feedModel)
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
                NavigationBar(title: "Adrenaline", diveMeetsID: $diveMeetsID, showAccount: $showAccount, contentHasScrolled: $contentHasScrolled, feedModel: $feedModel)
                    .frame(width: screenWidth)
            }
        }
        .statusBar(hidden: !showStatusBar)
    }
}

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


//struct FeedBase_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedBase()
//    }
//}
