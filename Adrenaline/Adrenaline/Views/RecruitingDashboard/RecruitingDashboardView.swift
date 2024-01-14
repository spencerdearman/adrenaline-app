//
//  RecruitingDashboardView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/7/24.
//

import SwiftUI
import Amplify

enum RecruitingSheet {
    case user
    case divers
    case results
}

struct RecruitingDashboardView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Namespace var namespace
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @State private var favorites: [NewUser] = []
    // showSheet is updated with changes to selectedSheet and should not be set manually
    @State private var showSheet: Bool = false
    @State private var selectedSheet: RecruitingSheet? = nil
    @State private var selectedUser: NewUser? = nil
    @State private var newPosts: [PostProfileItem] = []
    @State private var selectedPost: String? = nil
    // Added to satisfy PostProfileItem constructor, but none of these posts will be editable by
    // the coach
    @State private var shouldRefreshPosts: Bool = false
    @State private var newResults: [String] = []
    @ObservedObject var newUserViewModel: NewUserViewModel
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private var newUser: NewUser? {
        newUserViewModel.newUser
    }
    
    private let screenWidth = UIScreen.main.bounds.width
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    trackedDiversView
                        .padding(.bottom)
                    
                    newResultsView
                        .padding(.bottom)
                    
                    VStack {
                        HStack {
                            Text("New Posts")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }

                        newPostsView
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .offset(y: 80)
        .padding([.leading, .trailing])
        .sheet(isPresented: $showSheet) {
            switch selectedSheet {
                case .user:
                    NavigationView {
                        if let user = selectedUser {
                            AdrenalineProfileView(newUser: user)
                        }
                    }
                case .divers:
                    ExpandedDiversView(divers: $favorites)
                case .results:
                    Text("")
                case nil:
                    EmptyView()
            }
        }
        .overlay {
            if feedModel.showTab {
                NavigationBar(title: "Recruiting",
                              newUser: $newUserViewModel.newUser,
                              showAccount: $showAccount,
                              contentHasScrolled: $contentHasScrolled,
                              feedModel: $feedModel,
                              recentSearches: $recentSearches,
                              uploadingPost: $uploadingPost)
                .frame(width: screenWidth)
            }
        }
        .onChange(of: selectedSheet) {
            switch selectedSheet {
                case .user:
                    showSheet = true
                    break
                case .divers, .results:
                    selectedUser = nil
                    showSheet = true
                    break
                default:
                    showSheet = false
            }
        }
        .onChange(of: showSheet) {
            if !showSheet {
                if selectedSheet == .divers {
                    if var user = newUser {
                        Task {
                            // id -> index mapping
                            let defaultOrder = user.favoritesIds.enumerated()
                                .reduce(into: [String: Int](), { result, item in
                                    let (index, id) = item
                                    result[id] = index
                                })
                            
                            let order = favorites.reduce(into: [Int](), { result, fav in
                                if let val = defaultOrder[fav.id] {
                                    result.append(val)
                                }
                            })
                            
                            guard var coach = try await user.coach else { print("Failed to load coach"); return }
                            coach.favoritesOrder = order
                            let savedCoach = try await saveToDataStore(object: coach)
                            user.setCoach(savedCoach)
                            
                            let _ = try await saveToDataStore(object: user)
                        }
                    }
                }
                
                selectedUser = nil
                selectedSheet = nil
            }
        }
        .onChange(of: appLogic.currentUserUpdated, initial: true) {
            Task {
                if !appLogic.currentUserUpdated {
                    guard let favsIds = newUser?.favoritesIds else { return }
                    let favUsers = try await getAthleteUsersByFavoritesIds(ids: favsIds)
                    guard let order = try await newUser?.coach?.favoritesOrder else {
                        print("Failed to get order")
                        favorites = favUsers
                        return
                    }
                    
                    if favUsers.count != order.count {
                        print("order mismatch")
                        favorites = favUsers
                    } else {
                        favorites = order.map { favUsers[$0] }
                    }
                    
                    print("Favorites:", favorites.map { $0.firstName })
                }
            }
        }
        .onAppear {
            Task {
                guard let users = newUser?.favoritesIds else { print("Failed to get favorites"); return }
                let userPosts: [String: [Post]] = try await getPostsByUserIds(ids: users)
                var profileItems: [(Temporal.DateTime, PostProfileItem)] = []
                
                for (userId, posts) in userPosts {
                    // Get associated user for post
                    guard let user = try await queryAWSUserById(id: userId) else { continue }
                    
                    // Create PostProfileItem for each post and associate its creation date for
                    // future sorting
                    for post in posts {
                        let profileItem = try await PostProfileItem(user: user, post: post,
                                                          namespace: namespace,
                                                          postShowing: $selectedPost,
                                                          shouldRefreshPosts: $shouldRefreshPosts)
                        profileItems.append((post.creationDate, profileItem))
                    }
                }
                
                // Sort mixed post list in reverse chronological order
                newPosts = profileItems.sorted { $0.0 > $1.0 }.map { $0.1 }
            }
        }
    }
    
    var trackedDiversView: some View {
        VStack {
            HStack {
                Text("Tracked Divers")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                
                if favorites.count > 0 {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSheet = .divers
                        }
                }
            }
            
            if favorites.count == 0 {
                Text("You have not favorited any athletes yet")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(favorites, id: \.id) { fav in
                            VStack {
                                Text(fav.firstName + " " + fav.lastName)
                            }
                            .padding(20)
                            .background(.white)
                            .modifier(OutlineOverlay(cornerRadius: 30))
                            .backgroundStyle(cornerRadius: 30)
                            .padding(10)
                            .shadow(radius: 5)
                            .onTapGesture {
                                selectedUser = fav
                                selectedSheet = .user
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
    }
    
    var newResultsView: some View {
        VStack {
            HStack {
                Text("New Results")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                
                if newResults.count > 0 {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSheet = .results
                        }
                }
            }
            
            if newResults.count == 0 {
                Text("There are no new results posted yet")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(newResults, id: \.self) { newResult in
                            VStack {
                                Text(newResult)
                            }
                            .padding(20)
                            .background(.white)
                            .modifier(OutlineOverlay(cornerRadius: 30))
                            .backgroundStyle(cornerRadius: 30)
                            .padding(10)
                            .shadow(radius: 5)
                            // TODO: Add tap gesture here for results
//                            .onTapGesture {
//                                selectedResult = fav
//                                selectedSheet = .user
//                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
    }
    
    var newPostsView: some View {
        ZStack {
            if let selectedPost = selectedPost {
                ForEach($newPosts) { post in
                    if post.id == selectedPost {
                        AnyView(post.expandedView.wrappedValue)
                    }
                }
            }
            
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach($newPosts) { item in
                    AnyView(item.collapsedView.wrappedValue)
                }
                
                Text("You have seen all new posts")
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .padding([.leading, .trailing])
        .padding(.bottom, 100)
    }
}
