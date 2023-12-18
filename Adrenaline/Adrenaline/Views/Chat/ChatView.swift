//
//  ChatView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI
import Foundation
import Amplify
import Combine

struct ChatObjects {
    var conversations: [String: [(Message, Bool)]] = [:]
    var users: [NewUser] = []
}

struct ChatView: View {
    // Bindings
    @Binding var diveMeetsID: String
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    
    // Main States
    @Environment(\.colorScheme) var currentMode
    @AppStorage("authUserId") private var authUserId = ""
    @Namespace var namespace
    @State private var feedModel: FeedModel = FeedModel()
    @State private var lastUserOrder: [NewUser]? = nil
    @State private var currentUser: NewUser?
    @State private var showChatBar: Bool = false
    @State private var appear = [false, false, false]
    @State private var viewState: CGSize = .zero
    @State private var messageNotEmpty: Bool = false
    @State private var newMessages: Set<String> = Set()
    @State private var observedMessageIDs: Set<String> = Set()
    @State private var recipientMessageSubscription: AmplifyAsyncThrowingSequence<DataStoreQuerySnapshot<MessageNewUser>>?
    
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    // Message Selection States
    @State private var contentHasScrolled = false
    
    // Personal Chat States
    @State private var text: String = ""
    // All chat objects, regardless of type
    @State private var allChats = ChatObjects()
    // Active conversations and outgoing chat requests appear the same
    @State private var mainConversations = ChatObjects()
    // Incoming chat requests are placed in the "Chat Requests" section
    @State private var incomingChatRequests = ChatObjects()
    @State private var recipient: NewUser?
    // Current ChatObjects being referenced and displayed in lists and conversations
    // (this is swapped between mainConversations and incomingChatRequests depending on the view)
    @State private var currentChatObjects = ChatObjects()
    
    var body: some View {
        NavigationView {
            ZStack {
                (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
                if feedModel.showTab {
                    Image(currentMode == .light ? "MessageBackground-Light" : "MessageBackground-Dark")
                        .frame(width: screenWidth, height: screenHeight * 0.8)
                        .rotationEffect(Angle(degrees: 90))
                        .scaleEffect(0.9)
                        .offset(x: screenWidth * 0.15)
                }
                
                Group {
                    // If showChatBar is true, display individual conversation. Else show main
                    // conversation page
                    if showChatBar {
                        chatConversationView
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .matchedGeometryEffect(id: "form", in: namespace)
                        // When viewing main conversation page, but no users are present
                    } else if mainConversations.users.count == 0 {
                        VStack {
                            Text("You don't have any active conversations")
                                .foregroundColor(.secondary)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .modifier(OutlineOverlay(cornerRadius: 30))
                        .backgroundStyle(cornerRadius: 30)
                        .padding(20)
                        .padding(.vertical, 80)
                        .matchedGeometryEffect(id: "form", in: namespace)
                    } else {
                        ScrollView {
                            scrollDetection
                            VStack {
                                NavigationLink {
                                    chatRequestsView
                                } label: {
                                    HStack {
                                        Text("Chat Requests")
                                        Spacer()
                                        Text(String(incomingChatRequests.users.count))
                                    }
                                    .foregroundColor(.primary)
                                    .fontWeight(.semibold)
                                    .padding()
                                }
                                
                                Divider()
                                    .padding(.bottom, 10)
                                
                                ChatMessageListView(newMessages: $newMessages,
                                                    recipient: $recipient,
                                                    showChatBar: $showChatBar,
                                                    feedModel: $feedModel,
                                                    objects: $mainConversations,
                                                    currentChatObjects: $currentChatObjects,
                                                    columns: columns)
                            }
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .modifier(OutlineOverlay(cornerRadius: 30))
                            .backgroundStyle(cornerRadius: 30)
                            .padding(20)
                            .padding(.vertical, 80)
                        }
                        .matchedGeometryEffect(id: "form", in: namespace)
                    }
                }
            }
            .overlay {
                if feedModel.showTab {
                    MessagingBar(title: "Messaging",
                                 diveMeetsID: $diveMeetsID,
                                 showAccount: $showAccount,
                                 contentHasScrolled: $contentHasScrolled,
                                 feedModel: $feedModel,
                                 recentSearches: $recentSearches,
                                 recipient: $recipient,
                                 showChatBar: $showChatBar,
                                 mainConversations: $mainConversations,
                                 incomingChatRequests: $incomingChatRequests,
                                 currentChatObjects: $currentChatObjects)
                    .frame(width: screenWidth)
                } else {
                    if let recipient = recipient {
                        ChatBar(showChatBar: $showChatBar, feedModel: $feedModel, user: recipient)
                    }
                }
            }
        }
        .onAppear {
            // Get list of users to display in conversation list
            Task {
                // Get current user
                let mainUsersPredicate = NewUser.keys.id == authUserId
                let mainUsers = await queryAWSUsers(where: mainUsersPredicate)
                if mainUsers.count >= 1 {
                    currentUser = mainUsers[0]
                }
                
                //                let allUsersPredicate = NewUser.keys.id != currentUser?.id
                //                let allUsers = await queryAWSUsers(where: allUsersPredicate)
                //                if allUsers.count >= 1 {
                //                    if let lastOrder = lastUserOrder {
                //                        let extras = Set(allUsers).subtracting(Set(users))
                //                        users = Array(extras) + lastOrder
                //                    } else {
                //                        users = allUsers
                //                    }
                //                }
                
                // Observe new messages and build users list associated with current user
                observeNewMessages()
                
                currentChatObjects = mainConversations
            }
        }
        .onDisappear {
            lastUserOrder = mainConversations.users
        }
    }
    
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { offset in
            withAnimation(.easeInOut) {
                if offset < 0 {
                    contentHasScrolled = true
                } else {
                    contentHasScrolled = false
                }
            }
        }
    }
    
    var chatRequestsView: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ChatMessageListView(newMessages: $newMessages,
                                    recipient: $recipient,
                                    showChatBar: $showChatBar,
                                    feedModel: $feedModel,
                                    objects: $incomingChatRequests,
                                    currentChatObjects: $currentChatObjects,
                                    columns: columns)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
        .padding(20)
        .padding(.vertical, 80)
    }
    
    var chatConversationView: some View {
        VStack {
            ScrollView (showsIndicators: false) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 100)
                LazyVStack {
                    if let recipient = recipient,
                       let messages = currentChatObjects.conversations[recipient.id] {
                        ForEach(messages, id:\.0.id) { message, currentUserIsSender in
                            MessageRow(message: message,
                                       currentUserIsSender: currentUserIsSender)
                            .frame(maxWidth: .infinity,
                                   alignment:
                                    currentUserIsSender
                                   ? .trailing
                                   : .leading)
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            HStack {
                TextField("Enter message", text: $text)
                    .onChange(of: text, initial: true) { _, newText in
                        if text != "" {
                            messageNotEmpty = true
                        } else {
                            messageNotEmpty = false
                        }
                    }
                Button {
                    if messageNotEmpty {
                        Task {
                            //Actual Sending Procedure
                            if let currentUser = currentUser,
                               let recipient = recipient {
                                didTapSend(message: text, sender: currentUser,
                                           recipient: recipient)
                                
                                text.removeAll()
                            } else {
                                print("Errors retrieving users")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(messageNotEmpty ? .blue.opacity(0.7) :
                                .blue.opacity(0.4))
                        .frame(width: 40, height: 40)
                        .scaleEffect(1.6)
                }
            }
            .padding(.leading, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .modifier(OutlineOverlay(cornerRadius: 30))
        }
    }
    
    // This function is used to observe changes in the Message model
    func observeNewMessages() {
        // Set up a subscription to observe new messages
        let messageSubscription = Amplify.DataStore.observeQuery(for: Message.self)
        
        Task {
            do {
                for try await querySnapshot in messageSubscription {
                    // Dict of keys of user Ids and values of  datetimes of the least recently sent
                    // message in that conversation. This will be how the users array is updated at
                    // the end to sort descending by message send datetime
                    var sortOrder: [String: Temporal.DateTime] = [:]
                    var updatedConversations: Set<String> = Set()
                    for message in querySnapshot.items {
                        // Check if the message ID has already been observed
                        if !observedMessageIDs.contains(message.id) {
                            // A new message has been created, you can update your UI here
                            //Updating Messages
                            if let currentUser = currentUser {
                                
                                let msgMessageNewUsers = message.MessageNewUsers
                                try await msgMessageNewUsers?.fetch()
                                
                                if let msgMessageNewUsers = msgMessageNewUsers {
                                    if msgMessageNewUsers.elements.count == 2 {
                                        let currentMessageNewUser: MessageNewUser
                                        let recipientMessageNewUser: MessageNewUser
                                        
                                        // If first element is current user
                                        if msgMessageNewUsers.elements[0].newuserID == currentUser.id {
                                            currentMessageNewUser = msgMessageNewUsers.elements[0]
                                            recipientMessageNewUser = msgMessageNewUsers.elements[1]
                                            // If second element is current user
                                        } else if msgMessageNewUsers.elements[1].newuserID ==
                                                    currentUser.id {
                                            currentMessageNewUser = msgMessageNewUsers.elements[1]
                                            recipientMessageNewUser = msgMessageNewUsers.elements[0]
                                            // If neither message is the current user, it is ignored
                                        } else {
                                            observedMessageIDs.insert(message.id)
                                            continue
                                        }
                                        
                                        //RecipientMessageNewUser has been assigned at this point
                                        let key = recipientMessageNewUser.newuserID
                                        let value = (message, currentMessageNewUser.isSender)
                                        
                                        // Update current user's conversation with recipient
                                        if !allChats.conversations.keys.contains(key) {
                                            allChats.conversations[key] = []
                                        }
                                        allChats.conversations[key]!.append(value)
                                        
                                        // If we haven't seen this person's conversation yet, just
                                        // add their creationDate directly
                                        if !sortOrder.keys.contains(key) {
                                            sortOrder[key] = message.creationDate
                                            // If we have already seen this person's conversation
                                            // and the incoming message was sent more recently than
                                            // the last we have seen, update the sortOrder
                                        } else if let val = sortOrder[key],
                                                  val < message.creationDate {
                                            sortOrder[key] = message.creationDate
                                        }
                                        
                                        updatedConversations.insert(key)
                                        
                                        // Update the observedMessageIDs set to mark this message as
                                        // observed
                                        observedMessageIDs.insert(message.id)
                                    } else {
                                        print("MessageNewUser count != 2")
                                    }
                                }
                            } else {
                                print("Error updating the users")
                            }
                        }
                    }
                    
                    // Sort each conversation's messages in chronological order
                    for userId in updatedConversations {
                        allChats.conversations[userId]! =
                        allChats.conversations[userId]!.sorted(by: {
                            $0.0.creationDate < $1.0.creationDate
                        })
                    }
                    
                    // Sorts all conversations in reverse chronological order by last sent message
                    // so the conversation list shows the most recent conversations at the top
                    let sorted = sortOrder.map { ($0.key, $0.value) }.sorted {
                        $0.1 > $1.1
                    }
                    
                    // Gets all user ids in sorted order
                    let sortedUserIds = sorted.map { $0.0 }
                    
                    // Iterate over all users that have messages with the current user and add any
                    // NewUser objects missing from the users list
                    let conversationUserIds = Set(allChats.users.map { $0.id })
                    for userId in sortedUserIds {
                        if !conversationUserIds.contains(userId) {
                            guard let user = try await Amplify.DataStore.query(NewUser.self,
                                                                               byId: userId) else {
                                continue
                            }
                            allChats.users.append(user)
                        }
                    }
                    
                    // Uses sortedUserIds to determine the appropriate indices for each of the users
                    // to be placed in based on this ordering
                    // https://stackoverflow.com/a/51683055/22068672
                    let reorderedUsers = allChats.users.sorted {
                        guard let first = sortedUserIds.firstIndex(of: $0.id) else { return false }
                        guard let second = sortedUserIds.firstIndex(of: $1.id) else { return true }
                        
                        return first < second
                    }
                    
                    withAnimation {
                        (mainConversations,
                         incomingChatRequests) =
                        separateChatRequests(conversations: allChats.conversations,
                                             users: reorderedUsers)
                    }
                    
                    // Assignment needs to follow user sorting in order for message ring to
                    // appear with the correct MessageRow
                    newMessages = updatedConversations
                    
                }
            } catch {
                print("Error observing new messages: \(error)")
            }
        }
    }
    
    // Separates conversations and users into active conversations and chat requests
    // Conversations is a dict mapping a recipient's user ID to a list of (Message, Bool) tuples
    // Users is a list of NewUser objects in the order they should appear on the main conversation
    // page
    // Returns (convo dict, convo user list, incoming chat req dict, incoming chat req user list,
    //          outgoing chat req dict, outgoing chat req user list)
    private func separateChatRequests(conversations: [String: [(Message, Bool)]],
                                      users: [NewUser]) -> (ChatObjects, ChatObjects) {
        var newConversations = ChatObjects()
        var incomingChatRequests = ChatObjects()
        
        for user in users {
            guard let messages = conversations[user.id] else {
                print("User not found in conversations")
                continue
            }
            
            // If only one message is in the list and they aren't the sender, incoming chat request
            if messages.count == 1, !messages[0].1 {
                print("incoming chat request")
                incomingChatRequests.conversations[user.id] = messages
                incomingChatRequests.users.append(user)
            } else {
                print("else")
                newConversations.conversations[user.id] = messages
                newConversations.users.append(user)
            }
        }
        
        print(newConversations)
        print(incomingChatRequests)
        print()
        return (newConversations, incomingChatRequests)
    }
}

struct ChatMessageListView: View {
    @Binding var newMessages: Set<String>
    @Binding var recipient: NewUser?
    @Binding var showChatBar: Bool
    @Binding var feedModel: FeedModel
    @Binding var objects: ChatObjects
    @Binding var currentChatObjects: ChatObjects
    var columns: [GridItem]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(objects.users.indices, id: \.self) { index in
                let user = objects.users[index]
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
                                    currentChatObjects = objects
                                }
                            }
                        }
                    }
            }
            .padding(.horizontal, 20)
        }
    }
}
