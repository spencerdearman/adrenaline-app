//
//  RecruitingDashboardView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/7/24.
//

import SwiftUI
import Amplify

private enum Sheet {
    case user
    case divers
    case results
}

struct RecruitingDashboardView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @State private var favorites: [NewUser] = []
    @State private var showSheet: Bool = false
    @State private var selectedSheet: Sheet? = nil
    @State private var selectedUser: NewUser? = nil
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Tracked Divers")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSheet = .divers
                            showSheet = true
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
                                    showSheet = true
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
            .padding(20)
        }
        .offset(y: 200)
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
                              newUser: $newUser,
                              showAccount: $showAccount,
                              contentHasScrolled: $contentHasScrolled,
                              feedModel: $feedModel,
                              recentSearches: $recentSearches,
                              uploadingPost: $uploadingPost)
                .frame(width: screenWidth)
            }
        }
        .onChange(of: showSheet) {
            if !showSheet {
                selectedUser = nil
                selectedSheet = nil
            }
        }
        .onChange(of: appLogic.currentUserUpdated, initial: true) {
            if !appLogic.currentUserUpdated {
                Task {
                    guard let favsIds = newUser?.favoritesIds else { return }
                    let favUsers = try await getAthleteUsersByFavoritesIds(ids: favsIds)
                    favorites = favUsers
                    //                    print("Favorites:", favorites.map { $0.id })
                }
            }
        }
    }
}
