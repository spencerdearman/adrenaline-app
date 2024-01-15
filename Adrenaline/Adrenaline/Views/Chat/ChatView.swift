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

typealias ChatConversations = [String: [(Message, Bool)]]

struct ChatView: View {
    @EnvironmentObject private var appLogic: AppLogic
    // Bindings
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var deletedChatIds: Set<String>
    
    // Main States
    @Environment(\.colorScheme) var currentMode
    @AppStorage("authUserId") private var authUserId = ""
    @Namespace var namespace
    @State private var feedModel: FeedModel = FeedModel()
    @State private var users: [NewUser] = []
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
    @State private var currentUserConversations: ChatConversations = [:]
    // Set of user IDs who have sent incoming chat requests to the current user
    @State private var incomingChatRequests: [NewUser] = []
    @State private var recipient: NewUser?
    @State private var isViewingChatRequest: Bool = false
    
    @State private var searchTerm: String = ""
    
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
                    } else if users.count == 0 {
                        VStack {
                            Text("Refreshing chats")
                                .foregroundColor(.secondary)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            ProgressView()
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .modifier(OutlineOverlay(cornerRadius: 30))
                        .backgroundStyle(cornerRadius: 30)
                        .padding(20)
                        .padding(.vertical, 80)
                        .matchedGeometryEffect(id: "form", in: namespace)
                    } else if appLogic.dataStoreReady && users.count == 0 {
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
                                if filteredChatRequests.count > 0 {
                                    NavigationLink {
                                        chatRequestsView
                                    } label: {
                                        HStack {
                                            Text("Chat Requests")
                                            Spacer()
                                            Text(String(filteredChatRequests.count))
                                        }
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                        .padding()
                                    }
                                }
                                
                                if filteredChatRequests.count > 0 && filteredChats.count > 0 {
                                    Divider()
                                        .padding(.bottom, 10)
                                }
                                
                                chatMessageListView
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
                                 newUser: $newUser,
                                 showAccount: $showAccount,
                                 contentHasScrolled: $contentHasScrolled,
                                 feedModel: $feedModel,
                                 recentSearches: $recentSearches,
                                 recipient: $recipient,
                                 showChatBar: $showChatBar)
                    .frame(width: screenWidth)
                } else {
                    if let recipient = recipient, let currentUser = currentUser {
                        ChatBar(showChatBar: $showChatBar,
                                feedModel: $feedModel,
                                deletedChatIds: $deletedChatIds,
                                isViewingChatRequest: $isViewingChatRequest,
                                user: recipient,
                                currentUser: currentUser)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // Manually clearing these since Amplify bug doesn't do this through the observeQuery
        .onChange(of: deletedChatIds) {
            for id in deletedChatIds {
                if let _ = currentUserConversations[id] {
                    currentUserConversations.removeValue(forKey: id)
                }
            }
            
            users = users.filter { !deletedChatIds.contains($0.id) }
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
            }
        }
        .onDisappear {
            lastUserOrder = users
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
    
    var filteredChats: [NewUser] {
        return users.filter {
            // Filters out chats that are requests or manually hidden from view
            if deletedChatIds.contains($0.id) ||
                Set(incomingChatRequests.map { $0.id }).contains($0.id) {
                return false
            }
            
            // Skip filtering on search term if it is empty
            guard !searchTerm.isEmpty else { return true }
            
            let name = $0.firstName + " " + $0.lastName
            return name.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    var filteredChatRequests: [NewUser] {
        guard !searchTerm.isEmpty else { return incomingChatRequests }
        return incomingChatRequests.filter {
            let name = $0.firstName + " " + $0.lastName
            return name.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    var chatMessageListView: some View {
        Group {
            if filteredChats.count > 0 {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(filteredChats.indices, id: \.self) { index in
                        let user = filteredChats[index]
                        if index != 0 { Divider() }
                        ProfileRow(user: user, newMessages: $newMessages)
                            .onTapGesture {
                                withAnimation {
                                    newMessages.remove(user.id)
                                    showChatBar = true
                                    feedModel.showTab = false
                                    searchTerm = ""
                                }
                                Task {
                                    let recipientPredicate = NewUser.keys.id == user.id
                                    let recipientUsers = await
                                    queryAWSUsers(where: recipientPredicate)
                                    if recipientUsers.count >= 1 {
                                        recipient = recipientUsers[0]
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                }
            } else if filteredChatRequests.count == 0 {
                VStack {
                    Spacer()
                    Text("No results found")
                    Text("Please try a different search term")
                    Spacer()
                }
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
            } else {
                EmptyView()
            }
        }
        .searchable(text: $searchTerm, placement: .navigationBarDrawer, prompt: "Search Chat")
    }
    
    var chatConversationView: some View {
        VStack {
            ScrollView (showsIndicators: false) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 100)
                LazyVStack {
                    if let recipient = recipient,
                       let messages = currentUserConversations[recipient.id] {
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
            // Chat Request overlay
            .overlay(alignment: .bottom) {
                if isViewingChatRequest {
                    VStack {
                        Text("Send a response to accept this chat request, or select an option below")
                            .foregroundColor(.secondary)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                        
                        HStack {
                            Spacer()
                            
                            Button(role: .destructive) {
                                print("Block")
                            } label: {
                                Text("Block")
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 15))
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                Task {
                                    if let currentUser = currentUser, let recipient = recipient {
                                        deletedChatIds.insert(recipient.id)
                                        try await deleteConversation(between: currentUser,
                                                                     and: recipient)
                                        
                                        // Dismiss view back to main conversation page
                                        withAnimation(.closeCard) {
                                            showChatBar = false
                                            feedModel.showTab = true
                                            isViewingChatRequest = false
                                        }
                                    }
                                }
                            } label: {
                                Text("Decline")
                                    .fontWeight(.semibold)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: 15))
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .modifier(OutlineOverlay(cornerRadius: 30))
                    .backgroundStyle(cornerRadius: 30)
                    .padding(20)
                }
            }
            
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
                                isViewingChatRequest = false
                                
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
    
    var chatRequestsView: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(filteredChatRequests.indices, id: \.self) { index in
                let user = filteredChatRequests[index]
                if index != 0 { Divider() }
                ProfileRow(user: user, newMessages: $newMessages)
                    .onTapGesture {
                        withAnimation {
                            newMessages.remove(user.id)
                            showChatBar = true
                            feedModel.showTab = false
                            isViewingChatRequest = true
                            searchTerm = ""
                        }
                        Task {
                            let recipientPredicate = NewUser.keys.id == user.id
                            let recipientUsers = await
                            queryAWSUsers(where: recipientPredicate)
                            if recipientUsers.count >= 1 {
                                recipient = recipientUsers[0]
                            }
                        }
                    }
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
        .padding(20)
        .padding(.vertical, 80)
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
                                        if !currentUserConversations.keys.contains(key) {
                                            currentUserConversations[key] = []
                                        }
                                        currentUserConversations[key]!.append(value)
                                        
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
                                        
                                        // Remove key from deleted chats if a new message was sent
                                        if deletedChatIds.contains(key) {
                                            deletedChatIds.remove(key)
                                        }
                                        
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
                        currentUserConversations[userId]! =
                        currentUserConversations[userId]!.sorted(by: {
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
                    
                    // Add users to the users list who have new messages to add
                    let conversationUserIds = Set(users.map { $0.id })
                    for userId in Set(sortedUserIds).subtracting(conversationUserIds) {
                        guard let user = try await Amplify.DataStore.query(NewUser.self,
                                                                           byId: userId) else {
                            continue
                        }
                        users.append(user)
                    }
                    
                    withAnimation {
                        // Uses sortedUserIds to determine the appropriate indices for each of the users
                        // to be placed in based on this ordering
                        // https://stackoverflow.com/a/51683055/22068672
                        users = users.sorted {
                            guard let first = sortedUserIds.firstIndex(of: $0.id) else { return false }
                            guard let second = sortedUserIds.firstIndex(of: $1.id) else { return true }
                            
                            return first < second
                        }
                        
                        incomingChatRequests = separateChatRequests(conversations: currentUserConversations,
                                                                    users: users)
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
}
