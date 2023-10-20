//
//  MessagesView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI
import Foundation
import Amplify
import Combine

struct Chat: View {
    // Bindings
    @Binding var email: String
    @Binding var diveMeetsID: String
    @Binding var showAccount: Bool
    
    // Main States
    @Environment(\.colorScheme) var currentMode
    @Namespace var namespace
    @State var feedModel: FeedModel = FeedModel()
    @State var users: [NewUser] = []
    @State var currentUser: NewUser?
    @State private var selection: Int = 0
    @State var appear = [false, false, false]
    @State var viewState: CGSize = .zero
    @State var messageNotEmpty: Bool = false
    @State var newMessages: Set<String> = Set()
    @State var observedMessageIDs: Set<String> = Set()
    @State var recipientMessageSubscription: AmplifyAsyncThrowingSequence<DataStoreQuerySnapshot<MessageNewUser>>?
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    // Message Selection States
    @State var contentHasScrolled = false
    
    // Personal Chat States
    @State var text: String = ""
    @State var currentUserConversations: [String : [(Message, Bool)]] = [:]
    @State var recipient: NewUser?
    
    var body: some View {
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
                switch selection {
                case 0:
                    ScrollView {
                        scrollDetection
                        VStack {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(users.indices, id: \.self) { index in
                                    let user = users[index]
                                    if index != 0 { Divider() }
                                    ProfileRow(user: user, newMessages: $newMessages)
                                        .onTapGesture {
                                            withAnimation {
                                                newMessages.remove(user.id)
                                                selection = 1
                                                feedModel.showTab = false
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
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .modifier(OutlineOverlay(cornerRadius: 30))
                        .backgroundStyle(cornerRadius: 30)
                        .padding(20)
                        .padding(.vertical, 80)
                    }
                    .matchedGeometryEffect(id: "form", in: namespace)
                    
                case 1:
                    VStack {
                        ScrollView (showsIndicators: false) {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 100)
                            LazyVStack {
                                if let recipient = recipient, let messages = currentUserConversations[recipient.id] {
                                    ForEach(messages, id:\.0.id) { message, currentUserIsSender in
                                        MessageRow(message: message, currentUserIsSender: currentUserIsSender)
                                            .frame(maxWidth: .infinity, alignment: currentUserIsSender ? .trailing
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
                                    text = newText
                                }
                            Button {
                                if messageNotEmpty {
                                    Task {
                                        //Actual Sending Procedure
                                        if let currentUser = currentUser, let recipient = recipient {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .matchedGeometryEffect(id: "form", in: namespace)
                default:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("DEFAULT")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                    }
                    .matchedGeometryEffect(id: "form", in: namespace)
                }
            }
        }
        .overlay{
            if feedModel.showTab {
                NavigationBar(title: "Messaging",
                              diveMeetsID: $diveMeetsID,
                              showAccount: $showAccount,
                              contentHasScrolled: $contentHasScrolled,
                              feedModel: $feedModel)
                .frame(width: screenWidth)
            } else {
                if let recipient = recipient {
                    ChatBar(selection: $selection, feedModel: $feedModel, user: recipient)
                }
            }
        }
        .onAppear {
            Task {
                let mainUsersPredicate = NewUser.keys.email == email
                let mainUsers = await queryAWSUsers(where: mainUsersPredicate)
                if mainUsers.count >= 1 {
                    currentUser = mainUsers[0]
                }
                let allUsersPredicate = NewUser.keys.id != currentUser?.id
                let allUsers = await queryAWSUsers(where: allUsersPredicate)
                if allUsers.count >= 1 {
                    users = allUsers
                }
                observeNewMessages()
            }
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

    // This function is used to observe changes in the Message model
    func observeNewMessages() {
        // Set up a subscription to observe new messages
        let messageSubscription = Amplify.DataStore.observeQuery(for: Message.self)
        Task {
            do {
                for try await querySnapshot in messageSubscription {
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
                                        if msgMessageNewUsers.elements[0].newuserID == currentUser.id {
                                            currentMessageNewUser = msgMessageNewUsers.elements[0]
                                            recipientMessageNewUser = msgMessageNewUsers.elements[1]
                                        } else if msgMessageNewUsers.elements[1].newuserID == currentUser.id {
                                            currentMessageNewUser = msgMessageNewUsers.elements[1]
                                            recipientMessageNewUser = msgMessageNewUsers.elements[0]
                                        } else {
                                            observedMessageIDs.insert(message.id)
                                            continue
                                        }
                                        
                                        //RecipientMessageNewUser has been assigned at this point
                                        let key = recipientMessageNewUser.newuserID
                                        let value = (message, currentMessageNewUser.isSender)
                                        
                                        if !currentUserConversations.keys.contains(key) {
                                            currentUserConversations[key] = []
                                        }
                                        currentUserConversations[key]!.append(value)
                                        updatedConversations.insert(key)
                                        
                                        // Update the observedMessageIDs set to mark this message as observed
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
                    for key in updatedConversations {
                        currentUserConversations[key]! = 
                        currentUserConversations[key]!.sorted(by: { $0.0.creationDate < $1.0.creationDate })
                    }
                    newMessages = updatedConversations
                }
            } catch {
                print("Error observing new messages: \(error)")
            }
        }
    }
}
