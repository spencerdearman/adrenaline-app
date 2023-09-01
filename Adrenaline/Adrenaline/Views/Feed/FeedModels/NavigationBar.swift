//
//  NavigationBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct NavigationBar: View {
    private let screenWidth = UIScreen.main.bounds.width
    var title = ""
    @State var showSheet = false
    @State var showAccount = true
    @State var isLogged = true
    @Binding var contentHasScrolled: Bool
    @Binding var feedModel : FeedModel
    
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
                    showSheet.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                }
                .sheet(isPresented: $showSheet) {
                    NewSearchView()
                }
                
                Button {
                    withAnimation {
                        if isLogged {
                            showAccount = true
                        }
                    }
                } label: {
                    AsyncImage(url: URL(string:
                    "https://secure.meetcontrol.com/divemeets/system/profilephotos/56961.jpg?&x=511121484"),
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
