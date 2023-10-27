//
//  NavigationBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import Amplify

struct NavigationBar: View {
    @EnvironmentObject var appLogic: AppLogic
    private let screenWidth = UIScreen.main.bounds.width
    var title = ""
    var diveMeetsID:  Binding<String>
    @State var showSearchSheet = false
    @State var showPostSheet = false
    @State var isLogged = true
    @Binding var showAccount: Bool
    @Binding var contentHasScrolled: Bool
    @Binding var feedModel : FeedModel
    
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
                .blur(radius: contentHasScrolled ? 10 : 0)
                .opacity(contentHasScrolled ? 1 : 0)
            
            Text(title)
                .animatableFont(size: contentHasScrolled ? 22 : 34, weight: .bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .opacity(contentHasScrolled ? 0.7 : 1)
            
            HStack(spacing: 16) {
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
                    NewPostView()
                }
                
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
                    NewSearchView()
                }
                
                Button {
                    withAnimation {
                        showAccount = true
                    }
                } label: {
                    Group {
                        if diveMeetsID.wrappedValue != "" {
                            AsyncImage(url: URL(string:
                                                    "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(diveMeetsID.wrappedValue).jpg?&x=511121484"),
                                       transaction: .init(animation: .easeOut)) { phase in
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
