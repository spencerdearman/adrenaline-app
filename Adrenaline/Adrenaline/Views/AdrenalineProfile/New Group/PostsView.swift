//
//  PostsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/2/23.
//

import SwiftUI
import Amplify

struct PostsView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @AppStorage("authUserId") private var authUserId: String = ""
    @Namespace var namespace
    @State private var posts: [PostProfileItem] = []
    @State private var postShowing: String? = nil
    @State private var shouldRefreshPosts: Bool = false
    @State private var currentUser: NewUser? = nil
    var newUser: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var currentUserIsCoach: Bool {
        if let current = currentUser {
            return current.accountType == "Coach"
        }
        
        return false
    }
    
    private func updatePosts() async throws {
        let pred = Post.keys.newuserID == newUser.id
        let postModels: [Post] = try await query(where: pred)
        var profileItems: [PostProfileItem] = []
        for post in postModels {
            // Shows all posts if current user is viewing their own profile, but if viewing a
            // different profile, skips posts that are marked coach only if the current user is not
            // a coach
            if currentUser?.id != newUser.id, !currentUserIsCoach, post.isCoachesOnly {
                continue
            }
            
            try await profileItems.append(PostProfileItem(user: newUser, post: post,
                                                          namespace: namespace,
                                                          postShowing: $postShowing,
                                                          shouldRefreshPosts: $shouldRefreshPosts))
        }
        
        // Sorts descending by date so most recent posts appear first
        posts = profileItems.sorted(by: {
            $0.post.creationDate > $1.post.creationDate
        })
    }
    
    var body: some View {
        let size: CGFloat = 125
        
        ZStack {
            if let showingId = postShowing {
                ForEach($posts) { post in
                    if post.post.wrappedValue.id == showingId {
                        AnyView(post.expandedView.wrappedValue)
                    }
                }
            }
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(size)), GridItem(.fixed(size)), GridItem(.fixed(size))]) {
                        ForEach($posts, id: \.id) { post in
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
                    try await updatePosts()
                    shouldRefreshPosts = false
                }
            }
        }
        .onAppear {
            Task {
                let pred = NewUser.keys.id == authUserId
                let users = await queryAWSUsers(where: pred)
                if users.count == 1 {
                    currentUser = users[0]
                }
                
                try await updatePosts()
            }
        }
    }
}
