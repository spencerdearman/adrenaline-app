//
//  ChatBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/7/23.
//


import SwiftUI
import Authenticator

struct ChatBar: View {
    @Environment(\.colorScheme) var currentMode
    @State var showSheet: Bool = false
    @Binding var showChatBar: Bool
    @Binding var feedModel: FeedModel
    @Binding var deletedChatIds: Set<String>
    @Binding var isViewingChatRequest: Bool
    // user is the recipient
    var user: NewUser
    // currentUser is the current account that is logged in
    var currentUser: NewUser
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private func goBack() {
        withAnimation(.closeCard) {
            showChatBar = false
            feedModel.showTab = true
            isViewingChatRequest = false
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(currentMode == .light ? .white : .black)
                .offset(y: -screenHeight * 0.4)
                .frame(height: 90, alignment: .top)
            
            HStack(spacing: 16) {
                Button {
                    goBack()
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
                
                if !isViewingChatRequest {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                deletedChatIds.insert(user.id)
                                try await deleteConversation(between: currentUser, and: user)
                                goBack()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Conversation")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                            .cornerRadius(10)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                            .transition(.scale.combined(with: .slide))
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink {
                    AdrenalineProfileView(newUser: user)
                } label: {
                    Image(systemName: "person")
                        .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                        .cornerRadius(10)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                        .transition(.scale.combined(with: .slide))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: screenHeight, alignment: .topTrailing)
            .padding()
        }
    }
}
