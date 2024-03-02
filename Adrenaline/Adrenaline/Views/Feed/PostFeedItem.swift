//
//  PostFeedItem.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 2/11/24.
//

import SwiftUI
import Amplify
import CachedAsyncImage

class PostFeedItem: FeedItem {
    var user: NewUser
    var post: Post
    var mediaItems: [PostMediaItem] = []
    
    init(user: NewUser, post: Post, namespace: Namespace.ID) async throws {
        self.user = user
        self.post = post
        super.init()
        self.mediaItems = try await getMediaItems()
        self.collapsedView = PostFeedItemCollapsedView(id: self.id,
                                                       namespace: namespace,
                                                       user: user, post: post,
                                                       mediaItems: mediaItems)
    }
    
    private func getMediaItems() async throws -> [PostMediaItem] {
        let videos = self.post.videos
        let images = self.post.images
        try await videos?.fetch()
        try await images?.fetch()
        
        var aggregateItems: [(Temporal.DateTime, PostMediaItem)] = []
        
        if let videos = videos {
            for video in videos.elements {
                aggregateItems.append((video.uploadDate,
                                       PostMediaItem(id: video.id, data: PostMedia.video(
                                        VideoPlayerViewModel(
                                            video: VideoItem(email: user.email, videoId: video.id),
                                            initialResolution: .p1080)), playVideoOnAppear: true,
                                                     videoIsLooping: true)))
            }
        }
        
        if let images = images {
            for image in images.elements {
                guard let url = URL(
                    string: "\(CLOUDFRONT_IMAGE_BASE_URL)\(user.email.replacingOccurrences(of: "@", with: "%40"))/\(image.id).jpg") else { continue }
                aggregateItems.append((image.uploadDate,
                                       PostMediaItem(id: image.id, data: PostMedia.asyncImage(
                                        CachedAsyncImage(url: url, urlCache: .imageCache) { phase in
                                            phase.image != nil
                                            ? AnyView(phase.image!
                                                .resizable()
                                                .aspectRatio(contentMode: .fit))
                                            : AnyView(ProgressView())}))))
            }
        }
        
        // Returns a list of PostMediaItems sorted ascending by upload date
        return aggregateItems.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
    }
}

struct PostFeedItemCollapsedView: View {
    @Environment(\.colorScheme) var currentMode
    @State var appear = [false, false, false]
    @State private var currentTab: String = ""
    var id: String
    var namespace: Namespace.ID
    var user: NewUser
    var post: Post
    var mediaItems: [PostMediaItem]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    // Indicator animation: https://www.youtube.com/watch?v=uo8gj7RT3H8
    private let indicatorSpacing: CGFloat = 5
    private let indicatorSize: CGFloat = 7
    private let selectedColor: Color = .accentColor
    private let dotColor: Color = Color.init(.init(gray: 0.7, alpha: 0.7))
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15),
                        radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background\(id)", in: namespace)
            VStack {
                VStack(alignment: .center, spacing: 16) {
                    
                    HStack {
                        LogoView(imageUrl: getProfilePictureURL(userId: user.id))
                            .shadow(radius: 10)
                        Text(user.firstName + " " + user.lastName)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    TabView(selection: $currentTab) {
                        ForEach(mediaItems, id: \.id) { item in
                            AnyView(item.view)
                                .tag(item.id)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea()
                    .frame(width: screenWidth * 0.9, height: screenHeight * 0.75)
                    
                    HStack(spacing: indicatorSpacing) {
                        ForEach(mediaItems, id: \.id) { item in
                            Circle()
                                .fill(currentTab == item.id ? selectedColor : dotColor)
                                .frame(width: indicatorSize,
                                       height: indicatorSize)
                        }
                    }
                    
                    Text(post.caption ?? "")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "caption\(id)", in: namespace)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)
            }
        }
        .frame(width: screenWidth * 0.9)
        .frame(minHeight: screenHeight * 0.4, maxHeight: screenHeight * 0.9)
        .onAppear {
            if !mediaItems.isEmpty {
                currentTab = mediaItems[0].id
            }
        }
    }
}
