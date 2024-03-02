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
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    // Only used to satisfy NavigationBar binding, otherwise unused
    @State private var feedModel: FeedModel = FeedModel()
    @State private var showStatusBar = true
    @State private var contentHasScrolled = false
    @State private var feedItems: [FeedItem] = []
    @State private var feedItemsLoaded: Bool = false
    @State private var tabBarState: Visibility = .visible
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        ZStack {
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
            
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
                
                if feedItemsLoaded {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach($feedItems) { item in
                            AnyView(item.collapsedView.wrappedValue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -80)
                } else {
                    VStack {
                        Text("Getting new posts")
                            .foregroundColor(.secondary)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        ProgressView()
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .modifier(OutlineOverlay(cornerRadius: 30))
                    .backgroundStyle(cornerRadius: 30)
                    .padding(20)
                    .padding(.vertical, 80)
                    .offset(y: 50)
                }
            }
            .dynamicTypeSize(.xSmall ... .xxLarge)
            .coordinateSpace(name: "scroll")
        }
        .onChange(of: newUser, initial: true) {
            Task {
                if let user = newUser {
                    try await user.posts?.fetch()
                    guard let posts = user.posts?.elements else { return }
                    
                    feedItems = try await posts.concurrentMap { post in
                        try await PostFeedItem(user: user, post: post, namespace: namespace)
                    }
                    feedItemsLoaded = true
                }
            }
        }
        .overlay {
            NavigationBar(title: "Adrenaline", newUser: $newUser,
                          showAccount: $showAccount, contentHasScrolled: $contentHasScrolled,
                          feedModel: $feedModel, recentSearches: $recentSearches, uploadingPost: $uploadingPost)
            .frame(width: screenWidth)
        }
        .statusBar(hidden: !showStatusBar)
    }
}

struct CloseButtonWithFeedModel: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var feedModel: FeedModel
    
    var body: some View {
        Button {
            feedModel.isAnimated ?
            withAnimation(.closeCard) {
                feedModel.showTile = false
                feedModel.selectedItem = ""
            }
            : presentationMode.wrappedValue.dismiss()
        } label: {
            CloseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(20)
        .padding(.top, 60)
        .ignoresSafeArea()
    }
}

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}
