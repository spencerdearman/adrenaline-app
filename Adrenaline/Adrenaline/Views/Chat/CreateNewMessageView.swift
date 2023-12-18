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
    @State private var objects = ChatObjects()
    @State private var currentUser: NewUser?
    @State private var newMessages: Set<String> = Set()
    @Binding var recipient: NewUser?
    @Binding var showChatBar: Bool
    @Binding var feedModel: FeedModel
    
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ChatMessageListView(newMessages: $newMessages,
                                    recipient: $recipient,
                                    showChatBar: $showChatBar,
                                    feedModel: $feedModel,
                                    objects: $objects,
                                    columns: columns)
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
                let allUsers = await queryAWSUsers(where: allUsersPredicate)
                if allUsers.count > 0 {
                    objects.users = allUsers
                }
            }
        }
    }
}
