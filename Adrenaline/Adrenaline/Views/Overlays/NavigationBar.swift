//
//  NavigationBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct NavigationBar: View {
    @EnvironmentObject var appLogic: AppLogic
    private let screenWidth = UIScreen.main.bounds.width
    var title = ""
    var showPlus: Bool = true
    var showSearch: Bool = true
    @State private var showSearchSheet = false
    @State private var showPostSheet = false
    @State private var isLogged = true
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var contentHasScrolled: Bool
    @Binding var feedModel : FeedModel
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    // Using this function to swap sheet bools safely
    private func showSheet(showingPost: Bool) {
        if showingPost {
            showSearchSheet = false
            showPostSheet = true
        } else {
            showPostSheet = false
            showSearchSheet = true
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .frame(maxHeight: .infinity, alignment: .top)
                .blur(radius: contentHasScrolled ? 20 : 0).ignoresSafeArea()
                .opacity(contentHasScrolled ? 0.4 : 0)
            
            Text(title)
                .animatableFont(size: contentHasScrolled ? 22 : 34, weight: .bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .opacity(contentHasScrolled ? 0.7 : 1)
            
            HStack(spacing: 16) {
                if showPlus {
                    Button {
                        showSheet(showingPost: true)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                    }
                    .sheet(isPresented: $showPostSheet) {
                        NewPostView(uploadingPost: $uploadingPost)
                    }
                }
                
                if showSearch {
                    Button {
                        showSheet(showingPost: false)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                    }
                    .sheet(isPresented: $showSearchSheet) {
                        NewSearchView(recentSearches: $recentSearches)
                    }
                }
                
                Button {
                    withAnimation {
                        showAccount = true
                    }
                } label: {
                    Group {
                        if let user = newUser,
                           let url = URL(string: getProfilePictureURL(
                            userId: user.id,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            dateOfBirth: user.dateOfBirth)
                           ) {
                            AsyncImage(url: url, transaction: .init(animation: .easeOut)) { phase in
                                switch phase {
                                    case .empty:
                                        Color.white
                                    case .success(let image):
                                        image.resizable()
                                    case .failure(_):
                                        Color.gray
                                    @unknown default:
                                        Color.gray
                                }
                            }
                        } else {
                            Color.white
                        }
                    }
                    .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                    .cornerRadius(10)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                    .transition(.scale.combined(with: .slide))
                }
                .accessibilityElement()
                .accessibilityLabel("Account")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
        }
        .offset(y: feedModel.showNav ? 0 : -120)
        .accessibility(hidden: !feedModel.showNav)
        .offset(y: contentHasScrolled ? -16 : 0)
    }
}
