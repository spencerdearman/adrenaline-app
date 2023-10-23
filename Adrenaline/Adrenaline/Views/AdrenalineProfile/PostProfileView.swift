//
//  PostProfileView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/22/23.
//

import SwiftUI
import Amplify

struct PostProfileItem: Hashable, Identifiable {
    let id = UUID().uuidString
    var post: Post
    var email: String
    var mediaItems: [PostMediaItem] = []
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
    
    init(post: Post, email: String, namespace: Namespace.ID,
         postShowing: Binding<String?>) async throws {
        self.post = post
        self.email = email
        self.mediaItems = try await getMediaItems()
        
        self.collapsedView = PostProfileCollapsedView(postShowing: postShowing, id: self.id,
                                                      namespace: namespace,
                                                      post: self.post, email: self.email, firstMediaItem: self.mediaItems.first)
        self.expandedView = PostProfileExpandedView(postShowing: postShowing, id: self.id,
                                                    namespace: namespace,
                                                    post: self.post, email: self.email, mediaItems: self.mediaItems)
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
                                            video: VideoItem(email: email, videoId: video.id),
                                            initialResolution: .p1080)))))
            }
        }
        
        if let images = images {
            for image in images.elements {
                guard let url = URL(
                    string: "\(CLOUDFRONT_IMAGE_BASE_URL)\(email.replacingOccurrences(of: "@", with: "%40"))/\(image.id).jpg") else { continue }
                aggregateItems.append((image.uploadDate,
                                       PostMediaItem(id: image.id, data: PostMedia.asyncImage(
                                        AsyncImage(url: url) { phase in
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
    
    static func == (lhs: PostProfileItem, rhs: PostProfileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PostProfileCollapsedView: View {
    @Environment(\.colorScheme) var currentMode
    @State private var thumbnail: URL? = nil
    @Binding var postShowing: String?
    var id: String
    var namespace: Namespace.ID
    var post: Post
    var email: String
    var firstMediaItem: PostMediaItem?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            if let imageURL = thumbnail {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .onTapGesture {
                            withAnimation(.openCard) {
                                postShowing = post.id
                            }
                        }
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            }
        }
        
        .onAppear {
            // Get first piece of media from post to use as thumbnail if not yet assigned
            if thumbnail == nil, let item = firstMediaItem {
                Task {
                    if case let .video(v) = item.data {
                        guard let url = URL(string: v.thumbnailURL) else { return }
                        thumbnail = url
                    } else {
                        guard let url = URL(string: "\(CLOUDFRONT_IMAGE_BASE_URL)\(email.replacingOccurrences(of: "@", with: "%40"))/\(item.id).jpg") else { return }
                        thumbnail = url
                    }
                }
            }
        }
    }
}

struct PostProfileExpandedView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var postShowing: String?
    var id: String
    var namespace: Namespace.ID
    var post: Post
    var email: String
    var mediaItems: [PostMediaItem]
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15),
                        radius: 15, x: 0, y: 30)
            
            VStack {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(mediaItems) { item in
                            AnyView(item.view)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .padding(.horizontal, 30)
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
                
                
                HStack(alignment: .top) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .backgroundStyle(opacity: 0.4)
                            .shadow(color: .gray.opacity(0.15), radius: 5)
                        
                        Text(post.caption ?? "")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .frame(width: screenWidth * 0.8)
                    
                    Menu {
                        Button {
                            print("Editing")
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                        }
                        Button {
                            print("Deleting")
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .foregroundStyle(Color.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 28, weight: .light))
                            .frame(width: 48, height: 48)
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                            .shadow(color: .gray.opacity(0.15), radius: 5)
                    }
                    
                }
            }
            .padding()
            
            CloseButtonWithPostShowing(postShowing: $postShowing)
        }
        .zIndex(10)
    }
}

struct CloseButtonWithPostShowing: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var postShowing: String?
    
    var body: some View {
        Button {
            withAnimation(.closeCard) {
                postShowing = nil
            }
        } label: {
            CloseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(25)
        .ignoresSafeArea()
    }
}
