//
//  CreateNewMessageView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 12/17/23.
//

import SwiftUI
import Amplify

struct CreateNewMessageView: View {
    @AppStorage("authUserId") private var authUserId = ""
    @State private var currentUser: NewUser?
    // users available to send a new message to
    @State private var users: [NewUser] = []
    // State newMessages to satisfy ProfileRow view, but not actually used in this context
    @State private var newMessages: Set<String> = Set()
    // objects should be outgoingChatRequests so chats can be updated in real time as messages are
    // sent
    @Binding var recipient: NewUser?
    @Binding var showChatBar: Bool
    @Binding var feedModel: FeedModel
    
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(users.indices, id: \.self) { index in
                    let user = users[index]
                    if index != 0 { Divider() }
                    ProfileRow(user: user, newMessages: $newMessages)
                        .onTapGesture {
                            Task {
                                let recipientPredicate = NewUser.keys.id == user.id
                                let recipientUsers = await
                                queryAWSUsers(where: recipientPredicate)
                                if recipientUsers.count == 1 {
                                    recipient = recipientUsers[0]
                                    
                                    withAnimation {
                                        newMessages.remove(user.id)
                                        showChatBar = true
                                        feedModel.showTab = false
                                    }
                                }
                            }
                        }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
        .padding(20)
        .padding(.vertical, 80)
        .onAppear {
            Task {
                // Get current user
                let mainUsersPredicate = NewUser.keys.id == authUserId
                let mainUsers = await queryAWSUsers(where: mainUsersPredicate)
                if mainUsers.count >= 1 {
                    currentUser = mainUsers[0]
                }
                
                let allUsersPredicate = NewUser.keys.id != currentUser?.id
                users = await queryAWSUsers(where: allUsersPredicate)
            }
        }
    }
}
