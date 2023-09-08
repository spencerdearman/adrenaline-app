//
//  ChatBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/7/23.
//


import SwiftUI
import Authenticator

struct ChatBar: View {
    @State var showSheet: Bool = false
    @Binding var selection: Int
    @Binding var feedModel: FeedModel
    var user: NewUser
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.closeCard) {
                        selection -= 1
                        feedModel.showTab = true
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                }
                
                Text("\(user.firstName) \(user.lastName)")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)

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

                NavigationLink {

                } label: {
                    Image(systemName: "person")
                    .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                    .cornerRadius(10)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                    .transition(.scale.combined(with: .slide))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: screenHeight, alignment: .topTrailing)
            .padding()
        }
    }
}
