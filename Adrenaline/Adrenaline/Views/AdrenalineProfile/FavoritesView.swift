//
//  FavoritesView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/2/23.
//

import SwiftUI


struct FavoritesView: View {
    // Real-time list of all non-spectator users in the DataStore
    @Environment(\.newUsers) private var allUsers
    @State private var favoriteUsers: [NewUser] = []
    @State private var showSheet: Bool = false
    @State private var selectedUser: NewUser? = nil
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    var newUser: NewUser
    
    private let cornerRadius: CGFloat = 30
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        ZStack {
            if favoriteUsers.isEmpty {
                Text("You haven't favorited any users yet")
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(favoriteUsers) { favorite in
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Custom.specialGray)
                                    .shadow(radius: 5)
                                HStack(alignment: .center) {
                                    ProfileImage(diverID: favorite.diveMeetsID ?? "")
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(0.3)
                                    HStack(alignment: .firstTextBaseline) {
                                        Text((favorite.firstName) + " " + (favorite.lastName))
                                            .padding()
                                        Text(favorite.accountType)
                                            .foregroundColor(Custom.secondaryColor)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                            .padding([.leading, .trailing])
                            .onTapGesture {
                                print("Tapped")
                                selectedUser = favorite
                                showSheet = true
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, maxHeightOffset)
                }
            }
        }
        .onChange(of: showSheet) {
            if !showSheet {
                selectedUser = nil
            }
        }
        .sheet(isPresented: $showSheet) {
            NavigationView {
                if let user = selectedUser {
                    AdrenalineProfileView(newUser: user)
                }
            }
        }
        .onAppear {
            Task {
                favoriteUsers = []
                
                // Gets updated current user to compare favorites ids
                let currentUsers = allUsers.filter { $0.id == newUser.id }
                if currentUsers.count != 1 {
                    return
                }
                let user = currentUsers[0]
                
                // Filters out current user's favorites from all users
                let ids = user.favoritesIds
                let favorites = allUsers.filter { ids.contains($0.id) }
                
                favoriteUsers = favorites
            }
        }
    }
}
