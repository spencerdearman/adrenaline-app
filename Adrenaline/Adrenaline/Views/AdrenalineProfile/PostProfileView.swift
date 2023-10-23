//
//  PostProfileView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/22/23.
//

import SwiftUI
import Amplify

struct PostProfileItem: Hashable, Identifiable {
    static func == (lhs: PostProfileItem, rhs: PostProfileItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id = UUID().uuidString
    var post: Post
    var email: String
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
    
    init(post: Post, email: String, namespace: Namespace.ID, postShowing: Binding<String?>) {
        self.post = post
        self.email = email
        self.collapsedView = PostProfileCollapsedView(postShowing: postShowing, id: self.id,
                                                      namespace: namespace,
                                                      post: self.post, email: self.email)
        self.expandedView = PostProfileExpandedView(postShowing: postShowing, id: self.id,
                                                    namespace: namespace,
                                                    post: self.post, email: self.email)
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
            if thumbnail == nil {
                Task {
                    let videos = post.videos
                    let images = post.images
                    try await videos?.fetch()
                    try await images?.fetch()
                    
                    var earliestMedia: (Temporal.DateTime, String)? = nil
                    
                    if let videos = videos {
                        for video in videos.elements {
                            if earliestMedia == nil || video.uploadDate < earliestMedia!.0 {
                                earliestMedia = (video.uploadDate,
                                                 getVideoThumbnailURL(email: email,
                                                                      videoId: video.id))
                            }
                        }
                    }
                    
                    if let images = images {
                        for image in images.elements {
                            if earliestMedia == nil || image.uploadDate < earliestMedia!.0 {
                                earliestMedia = (image.uploadDate,
                                                 "\(CLOUDFRONT_IMAGE_BASE_URL)\(email.replacingOccurrences(of: "@", with: "%40"))/\(image.id).jpg")
                            }
                        }
                    }
                    
                    guard let urlString = earliestMedia?.1,
                          let url = URL(string: urlString) else { return }
                    thumbnail = url
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
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.red)
            
            Text("\(post.id)")
            
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
