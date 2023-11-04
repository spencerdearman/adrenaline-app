//
//  SavedPostsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/2/23.
//

import SwiftUI
import Amplify

struct SavedPostsView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Namespace var namespace
    @State private var savedPosts: [PostProfileItem] = []
    @State private var postShowing: String? = nil
    @State private var shouldRefreshPosts: Bool = false
    // Current profile being viewed, which if Saved posts is visible, should be current user
    var newUser: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private func updateSavedPosts() async throws {
        let savedPred = UserSavedPost.keys.newuserID == newUser.id
        let savedPostModels: [UserSavedPost] = try await query(where: savedPred)
        let savedPostIds = Set(savedPostModels.map { $0.postID })
        let postModels: [Post] = try await query().filter { savedPostIds.contains($0.id) }
        
        let users = await queryAWSUsers()
        
        var profileItems: [PostProfileItem] = []
        for post in postModels {
            let filteredUsers = users.filter { $0.id == post.newuserID }
            let user: NewUser
            if filteredUsers.count == 1 {
                user = filteredUsers[0]
            } else {
                continue
            }
            
            try await profileItems.append(PostProfileItem(user: user, post: post,
                                                          namespace: namespace,
                                                          postShowing: $postShowing,
                                                          shouldRefreshPosts: $shouldRefreshPosts))
        }
        
        // Sorts descending by date so most recent posts appear first
        savedPosts = profileItems.sorted(by: {
            $0.post.creationDate > $1.post.creationDate
        })
    }
    
    var body: some View {
        let size: CGFloat = 125
        
        ZStack {
            if let showingId = postShowing {
                ForEach($savedPosts) { post in
                    if post.post.wrappedValue.id == showingId {
                        AnyView(post.expandedView.wrappedValue)
                    }
                }
            }
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(size)), GridItem(.fixed(size)), GridItem(.fixed(size))]) {
                        ForEach($savedPosts, id: \.id) { post in
                            ZStack {
                                AnyView(post.collapsedView.wrappedValue)
                                    .frame(width: size, height: size)
                            }
                        }
                    }
                    .padding(.top)
            }
        }
        .onChange(of: shouldRefreshPosts) {
            if shouldRefreshPosts {
                Task {
                    try await updateSavedPosts()
                    shouldRefreshPosts = false
                }
            }
        }
        .onAppear {
            Task {
                try await updateSavedPosts()
            }
        }
    }
}
