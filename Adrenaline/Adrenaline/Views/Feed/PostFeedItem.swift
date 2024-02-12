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
    
    init(user: NewUser, post: Post, namespace: Namespace.ID, feedModel: Binding<FeedModel>) async throws {
        self.user = user
        self.post = post
        super.init()
        self.mediaItems = try await getMediaItems()
        self.collapsedView = PostFeedItemCollapsedView(feedModel: feedModel, id: self.id,
                                                       namespace: namespace,
                                                       user: user, post: post,
                                                       mediaItem: mediaItems.first)
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
    @Binding var feedModel: FeedModel
    var id: String
    var namespace: Namespace.ID
    var user: NewUser
    var post: Post
    var mediaItem: PostMediaItem?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
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
                    
                    if let item = mediaItem {
                        PostMediaItemView(item: item, id: self.id, namespace: namespace)
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .background(.grayThinMaterial)
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
    }
}

struct PostFeedItemExpandedView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    @State var viewState: CGSize = .zero
    @State var showSection = false
    @State var appear = [false, false, false]
    @Binding var feedModel: FeedModel
    var id: String
    var namespace: Namespace.ID
    var user: NewUser
    var post: Post
    var mediaItems: [PostMediaItem]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            ScrollView {
                cover
            }
            .coordinateSpace(name: "scroll")
            .background(currentMode == .light ? Color.white : Color.black)
            .mask(RoundedRectangle(cornerRadius: appear[0] ? 0 : 30))
            .mask(RoundedRectangle(cornerRadius: viewState.width / 3))
            .modifier(OutlineModifier(cornerRadius: viewState.width / 3))
            .scaleEffect(-viewState.width/500 + 1)
            .background(.ultraThinMaterial)
            .gesture(feedModel.isAnimated ? drag : nil)
            .ignoresSafeArea()
            
            CloseButtonWithFeedModel(feedModel: $feedModel)
        }
        .frame(maxWidth: screenWidth)
        .zIndex(1)
        .onAppear {
            fadeIn()
        }
        .onChange(of: feedModel.showTile) {
            fadeOut()
        }
    }
    
    var cover: some View {
        GeometryReader { proxy in
            let scrollY = proxy.frame(in: .named("scroll")).minY
            
            VStack {
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: scrollY > 0 ? 500 + scrollY : 500)
            .background(
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(mediaItems) { item in
                            PostMediaItemView(item: item, id: self.id, namespace: namespace)
                                .containerRelativeFrame(.horizontal)
                                .scrollTransition(.animated, axis: .horizontal) {
                                    content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.8)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                }
                        }
                    }
                    .frame(height: 450)
                    
                }
                    .scrollTargetBehavior(.paging)
            )
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .matchedGeometryEffect(id: "background\(id)", in: namespace)
                    .mask(RoundedRectangle(cornerRadius: 30))
                    .offset(y: scrollY > 0 ? -scrollY : 0)
                    .scaleEffect(scrollY > 0 ? scrollY / 1000 + 1 : 1)
                    .blur(radius: scrollY > 0 ? scrollY / 10 : 0)
                    .accessibility(hidden: true)
                    .ignoresSafeArea()
            )
            .mask(
                RoundedRectangle(cornerRadius: appear[0] ? 0 : 30)
                    .matchedGeometryEffect(id: "mask\(id)", in: namespace)
                    .offset(y: scrollY > 0 ? -scrollY : 0)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        LogoView(imageUrl: getProfilePictureURL(userId: user.id))
                        Text(user.firstName + " " + user.lastName)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(appear[1] ? 1 : 0)
                    .accessibilityElement(children: .combine)
                    
                    Divider()
                        .foregroundColor(.secondary)
                        .opacity(appear[1] ? 1 : 0)
                    
                    Text("Location / Competition".uppercased())
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
                    
                    Text(post.caption ?? "")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "caption\(id)", in: namespace)
                }
                    .padding(20)
                    .padding(.vertical, 10)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .cornerRadius(30)
                            .blur(radius: 30)
                            .matchedGeometryEffect(id: "blur\(id)", in: namespace)
                            .opacity(appear[0] ? 0 : 1)
                    )
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 30)
                            .opacity(appear[0] ? 1 : 0)
                    )
                    .offset(y: scrollY > 0 ? -scrollY * 1.8 : 0)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .offset(y: screenHeight * 0.28)
                    .padding(20)
            )
        }
        .frame(height: screenHeight)
    }
    
    func close() {
        withAnimation {
            viewState = .zero
        }
        withAnimation(.closeCard.delay(0.2)) {
            feedModel.showTile = false
            feedModel.selectedItem = ""
        }
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onChanged { value in
                guard value.translation.width > 0 else { return }
                
                if value.startLocation.x < 100 {
                    withAnimation {
                        viewState = value.translation
                    }
                }
                
                if viewState.width > 120 {
                    close()
                }
            }
            .onEnded { value in
                if viewState.width > 80 {
                    close()
                } else {
                    withAnimation(.openCard) {
                        viewState = .zero
                    }
                }
            }
    }
    
    func fadeIn() {
        withAnimation(.easeOut.delay(0.3)) {
            appear[0] = true
        }
        withAnimation(.easeOut.delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.easeOut.delay(0.5)) {
            appear[2] = true
        }
    }
    
    func fadeOut() {
        withAnimation(.easeIn(duration: 0.1)) {
            appear[0] = false
            appear[1] = false
            appear[2] = false
        }
    }
}
