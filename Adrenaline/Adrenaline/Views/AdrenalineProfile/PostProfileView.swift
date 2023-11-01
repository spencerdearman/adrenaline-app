//
//  PostProfileView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/22/23.
//

import SwiftUI
import Amplify
import CachedAsyncImage

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}

struct PostProfileItem: Hashable, Identifiable {
    let id = UUID().uuidString
    var user: NewUser
    var post: Post
    var mediaItems: [PostMediaItem] = []
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
    
    init(user: NewUser, post: Post, namespace: Namespace.ID,
         postShowing: Binding<String?>, shouldRefreshPosts: Binding<Bool>) async throws {
        self.user = user
        self.post = post
        self.mediaItems = try await getMediaItems()
        
        self.collapsedView = PostProfileCollapsedView(postShowing: postShowing, id: self.id,
                                                      namespace: namespace, user: self.user,
                                                      post: self.post,
                                                      firstMediaItem: self.mediaItems.first)
        self.expandedView = PostProfileExpandedView(postShowing: postShowing,
                                                    shouldRefreshPosts: shouldRefreshPosts, id: self.id,
                                                    namespace: namespace, user: self.user,
                                                    post: self.post, mediaItems: self.mediaItems)
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
                                            initialResolution: .p1080)))))
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
    let id: String
    let namespace: Namespace.ID
    let user: NewUser
    let post: Post
    var firstMediaItem: PostMediaItem?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            if let imageURL = thumbnail {
                CachedAsyncImage(url: imageURL, urlCache: .imageCache) { image in
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
                ProgressView()
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
                        guard let url = URL(string: "\(CLOUDFRONT_IMAGE_BASE_URL)\(user.email.replacingOccurrences(of: "@", with: "%40"))/\(item.id).jpg") else { return }
                        thumbnail = url
                    }
                }
            }
        }
    }
}

struct PostProfileExpandedView: View {
    @Environment(\.colorScheme) var currentMode
    // authUserId is the userId of the current user
    @AppStorage("authUserId") private var authUserId: String = ""
    @State private var showingAlert: Bool = false
    @State private var isEditingPost: Bool = false
    @State private var savedPost: UserSavedPost? = nil
    @State private var currentUser: NewUser? = nil
    @State private var caption: String = ""
    @Binding var postShowing: String?
    @Binding var shouldRefreshPosts: Bool
    let id: String
    let namespace: Namespace.ID
    // user is the user that owns the post
    let user: NewUser
    // post is the post owned by the above user
    let post: Post
    var mediaItems: [PostMediaItem]
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    // Checks UserSavedPost to see if viewing user has saved this post, and if yes, assign
    // it to the State to be removed if the user unsaves
    private func getSavedPost() async throws {
        let pred = UserSavedPost.keys.newuserID == authUserId &&
        UserSavedPost.keys.postID == post.id
        let savedPosts: [UserSavedPost] = try await query(where: pred)
        if savedPosts.count == 1 {
            print("Found saved post")
            savedPost = savedPosts[0]
        } else {
            print("No single post found, setting to nil")
            savedPost = nil
        }
    }
    
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
                        if isEditingPost {
                            TextField("Caption", text: $caption, axis: .vertical)
                                .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .background(.ultraThinMaterial)
                                .backgroundStyle(cornerRadius: 14, opacity: 0.15)
                                .shadow(color: .gray.opacity(0.3), radius: 5)
                                .lineLimit(6, reservesSpace: true)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .backgroundStyle(opacity: 0.4)
                                .shadow(color: .gray.opacity(0.15), radius: 5)
                            
                            Text(post.caption ?? "")
                                .foregroundColor(.secondary)
                                .padding()
                                .lineLimit(6, reservesSpace: true)
                        }
                    }
                    .frame(width: screenWidth * 0.8)
                    
                    VStack {
                        if isEditingPost {
                            Button {
                                Task {
                                    var newPost = post
                                    newPost.caption = caption
                                    let _ = try await saveToDataStore(object: newPost)
                                    shouldRefreshPosts = true
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .light))
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.secondary)
                                    .background(.ultraThinMaterial)
                                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                                    .shadow(color: .gray.opacity(0.15), radius: 5)
                            }
                            
                            Button {
                                isEditingPost = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 28, weight: .light))
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.secondary)
                                    .background(.ultraThinMaterial)
                                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                                    .shadow(color: .gray.opacity(0.15), radius: 5)
                            }
                        } else {
                            Menu {
                                // If post owner is current user
                                if authUserId == user.id {
                                    Button {
                                        Task {
                                            isEditingPost = true
                                            caption = post.caption ?? ""
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "pencil")
                                            Text("Edit")
                                        }
                                        .foregroundColor(.primary)
                                    }
                                    Button(role: .destructive) {
                                        showingAlert = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "trash.fill")
                                            Text("Delete")
                                        }
                                    }
                                    // If post owner is not current user and has already saved this post
                                } else if let saved = savedPost {
                                    Button {
                                        if let currentUser = currentUser {
                                            Task {
                                                try await userUnsavePost(user: currentUser, post: post,
                                                                         savedPost: saved)
                                                savedPost = nil
                                                postShowing = post.id
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "square.and.arrow.down.fill")
                                            Text("Saved")
                                        }
                                        .foregroundColor(.primary)
                                    }
                                    // If post owner is not current user and has not saved this post
                                } else {
                                    Button {
                                        if let currentUser = currentUser {
                                            Task {
                                                savedPost = try await userSavePost(user: currentUser,
                                                                                   post: post)
                                                postShowing = post.id
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "square.and.arrow.down")
                                            Text("Save")
                                        }
                                        .foregroundColor(.primary)
                                    }
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
                }
            }
            .padding()
            
            CloseButtonWithPostShowing(postShowing: $postShowing)
        }
        .zIndex(10)
        .alert("Are you sure you want to delete this post?", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) {
                print("Cancel delete")
                showingAlert = false
            }
            Button("Delete", role: .destructive) {
                Task {
                    print("Initiating deletion...")
                    
                    let _ = try await deletePost(user: user, post: post)
                    
                    showingAlert = false
                    shouldRefreshPosts = true
                    // Note: We reset postShowing in PostsView after it detects the change in
                    //       shouldRefreshPosts so we leave the user sitting on the expanded view
                    //       until the posts grid can be updated with the post removed
                }
            }
        }
        .onAppear {
            Task {
                try await getSavedPost()
                
                let pred = NewUser.keys.id == authUserId
                let users = await queryAWSUsers(where: pred)
                if users.count == 1 {
                    currentUser = users[0]
                }
            }
        }
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
