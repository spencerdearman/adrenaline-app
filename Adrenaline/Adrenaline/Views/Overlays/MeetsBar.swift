//
//  MeetsBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 12/17/23.
//

import SwiftUI
import Amplify
import CachedAsyncImage


struct MeetsBar: View {
    @EnvironmentObject var appLogic: AppLogic
    private let screenWidth = UIScreen.main.bounds.width
    var title = ""
    var userID:  Binding<String>
    @State private var showSearchSheet = false
    @State private var isLogged = true
    @Binding var selection: ViewType
    @Binding var showAccount: Bool
    @Binding var contentHasScrolled: Bool
    @Binding var feedModel : FeedModel
    @Binding var recentSearches: [SearchItem]
    
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
                Button {
                    withAnimation(.closeCard) {
                        if selection == .upcoming {
                            selection = .current
                        } else {
                            selection = .upcoming
                        }
                    }
                } label: {
                    Text(selection.rawValue)
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 100, height: 36)
                        .foregroundColor(.secondary)
                        .background(selection == .upcoming ? Color.blue.opacity(0.3) : Color.pink.opacity(0.3))
                        .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                }
                
                Button {
                    showSearchSheet = true
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
                
                Button {
                    withAnimation {
                        showAccount = true
                    }
                } label: {
                    Group {
                        if let url = URL(string: getProfilePictureURL(userId: userID.wrappedValue)) {
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
