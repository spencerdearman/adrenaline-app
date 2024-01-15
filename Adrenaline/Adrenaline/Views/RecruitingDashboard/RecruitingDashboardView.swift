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

typealias RecentResult = (MeetFeedItem, [NewUser])

struct RecentResultObject: Identifiable, Equatable {
    var id = UUID().uuidString
    var recentResult: RecentResult
    
    public static func == (lhs: RecentResultObject, rhs: RecentResultObject) -> Bool {
        lhs.id == rhs.id
    }
}

struct RecruitingDashboardView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Namespace var namespace
    @State private var contentHasScrolled: Bool = false
    @State private var resultsFeedModel: FeedModel = FeedModel()
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
    // MeetFeedItem and user ids that attended that meet
    @State private var recentResults: [RecentResultObject] = []
    @State private var selectedResult: String? = nil
    @ObservedObject var newUserViewModel: NewUserViewModel
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private var newUser: NewUser? {
        newUserViewModel.newUser
    }
    
    private let screenWidth = UIScreen.main.bounds.width
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    private func getLatestMeetForUser(data: EventHTMLDiverData, user: NewUser) throws -> MeetEvent? {
        var mainMeetLink: String = ""
        
        if data.count < 1 {
            print("Failed to get data")
            throw NSError()
        }
        
        var currentMeetEvents: [MeetEvent]? = []
        
        //Starting at 1 because the first meet in the dictionary has a key of 1
        if let value = data[1] {
            for (name, meetEvent) in value {
                // Gets all events inside a Meet
                for event in meetEvent {
                    let (place, score, link, meetLink) = event.value
                    mainMeetLink = meetLink
                    currentMeetEvents!.append(MeetEvent(name: event.key, place: Int(place),
                                                        score: score, isChild: true, link: link))
                }
                
                return MeetEvent(name: name, children: currentMeetEvents, link: mainMeetLink)
            }
        }
        
        return nil
    }
    
    private func getFavoritesRecentResults(ids: [String]) async throws -> [RecentResultObject] {
        // Main meet link -> [user ids]
        var meetLinkToUsers: [String: [NewUser]] = [:]
        // Main meet link -> MeetFeedItem
        var meetLinkToItem: [String: MeetFeedItem] = [:]
        
        for id in ids {
            let parser = EventHTMLParser()
            guard let user = try await queryAWSUserById(id: id) else {
                print("Failed to get user")
                throw NSError()
            }
            guard let diveMeetsID = user.diveMeetsID else {
                print("Failed to get diveMeetsID")
                throw NSError()
            }
            
            // Parse user's meets
            let profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + diveMeetsID
            await parser.parse(urlString: profileLink)
            
            // Get meets for each user from parser data
            let data = parser.myData
            guard let userMeet = try getLatestMeetForUser(data: data, user: user) else { continue }
            
            // Create MeetFeedItem and associate users with meet for all the user's meets
            guard let link = userMeet.link else { print("Failed to get link"); throw NSError() }
            // Add MeetFeedItem to dict
            if let meet = await MeetBase.from(meetEvent: userMeet) {
                meetLinkToItem[link] = MeetFeedItem(meet: meet,
                                                    namespace: namespace,
                                                    feedModel: $resultsFeedModel)
            }
            
            // Add user id to list of associated users to the meet link
            if !meetLinkToUsers.keys.contains(link) {
                meetLinkToUsers[link] = []
            }
            meetLinkToUsers[link]!.append(user)
        }
        
        // Combine MeetFeedItems and associated users
        // Throw error if meet dicts don't share identical sets of keys
        let linkKeys = Set(meetLinkToItem.keys)
        let usersKeys = Set(meetLinkToUsers.keys)
        if (linkKeys.intersection(usersKeys).count != linkKeys.count ||
            linkKeys.count != usersKeys.count) {
            print("Meet link dicts do not have identical keys")
            throw NSError()
        }
        
        // Safe to force unwrap after existence checking above
        return linkKeys.map {
            RecentResultObject(recentResult: (meetLinkToItem[$0]!, meetLinkToUsers[$0]!))
        } .sorted {
            $0.recentResult.0.meet.name < $1.recentResult.0.meet.name
        }
    }
    
    private func getFavoritesPosts(ids: [String]) async throws -> [PostProfileItem] {
        let userPosts: [String: [Post]] = try await getPostsByUserIds(ids: ids)
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
        
        return profileItems.sorted { $0.0 > $1.0 }.map { $0.1 }
    }
    
    private func getAttendeesString(_ users: [NewUser]) -> String {
        let names = users.map {
            var name = $0.firstName
            if let lastInitial = $0.lastName.first {
                name += " \(lastInitial)"
            }
            
            return name
        }
        var result = "Attended by "
        if users.count == 0 { return "" }
        else if users.count == 1 {
            result += names[0]
        } else if users.count == 2 {
            result += names.joined(separator: " and ")
        } else {
            result += names[..<2].joined(separator: ", ") + ", and others"
        }
        
        return result
    }
    
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
                    ExpandedResultsView(results: $recentResults)
                case nil:
                    EmptyView()
            }
        }
        .overlay {
            if resultsFeedModel.showTile {
                ForEach($recentResults) { result in
                    if result.recentResult.0.id == resultsFeedModel.selectedItem {
                        AnyView(result.recentResult.0.expandedView.wrappedValue)
                    }
                }
            }
            
            if resultsFeedModel.showTab {
                RecruitingDashboardBar(title: "Recruiting",
                              newUser: $newUserViewModel.newUser,
                              showAccount: $showAccount,
                              contentHasScrolled: $contentHasScrolled,
                              feedModel: $resultsFeedModel,
                              recentSearches: $recentSearches)
                .frame(width: screenWidth)
            }
        }
        .onChange(of: selectedSheet) {
            switch selectedSheet {
                case .user:
                    selectedResult = nil
                    showSheet = true
                    break
                case .divers:
                    selectedUser = nil
                    selectedResult = nil
                    showSheet = true
                    break
                case .results:
                    selectedUser = nil
                    showSheet = true
                    break
                default:
                    selectedUser = nil
                    selectedResult = nil
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
                selectedResult = nil
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
                    
                    recentResults = try await getFavoritesRecentResults(ids: favsIds)
                    newPosts = try await getFavoritesPosts(ids: favsIds)
                }
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
                
                if recentResults.count > 0 {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSheet = .results
                        }
                }
            }
            
            if recentResults.count == 0 {
                Text("There are no recent results posted yet")
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .multilineTextAlignment(.center)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach($recentResults) { result in
                            VStack {
                                AnyView(result.recentResult.0.collapsedView.wrappedValue)
                            }
                            .overlay {
                                VStack(alignment: .leading) {
                                    Spacer()
                                    Text(getAttendeesString(result.recentResult.1.wrappedValue).uppercased())
                                        .font(.footnote).bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.primary.opacity(0.7))
                                }
                                .padding(.bottom, 20)
                                .padding(.horizontal, 20)
                            }
                            .padding(.leading, 25)
                            .padding(.bottom, 25)
                            .scaleEffect(0.85)
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
