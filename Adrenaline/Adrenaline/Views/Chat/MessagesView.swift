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
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    // Message Selection States
    @State var contentHasScrolled = false
    
    // Personal Chat States
    @State var text: String = ""
    @State var messages: [(Message, Bool)] = []
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
                                    ProfileRow(user: user)
                                        .onTapGesture {
                                            withAnimation {
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
                                ForEach(messages.sorted(by: { $0.0.createdAt ?? .now() <
                                    $1.0.createdAt ?? .now() }), id: \.0.id) { message, b in
                                        MessageRow(message: message, b: b)
                                            .frame(maxWidth: .infinity, alignment: b ? .trailing
                                                   : .leading)
                                    }
                            }
                        }
                        HStack {
                            TextField("Enter message", text: $text)
                                .onChange(of: text) { newText in
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
                                        
                                        //Updating the CurrentUser Status
                                        let usersPredicate = NewUser.keys.email == email
                                        let users = await queryAWSUsers(where: usersPredicate)
                                        if users.count >= 1 {
                                            currentUser = users[0]
                                        }
                                        
                                        //Updating the Recipient Status
                                        let recipientPredicate = NewUser.keys.id == recipient?.id
                                        let recipients = await queryAWSUsers(where: recipientPredicate)
                                        if recipients.count >= 1 {
                                            recipient = recipients[0]
                                        }
                                        
                                        //Updating Messages
                                        if let currentUser = currentUser, let recipient = recipient {
                                            messages = await queryConversation(sender: currentUser,
                                                                               recipient: recipient)
                                        } else {
                                            print("Error updating the users")
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
                    .onAppear {
                        Task {
                            let usersPredicate = NewUser.keys.email == email
                            let users = await queryAWSUsers(where: usersPredicate)
                            if users.count >= 1 {
                                currentUser = users[0]
                            }
                            let recipientPredicate = NewUser.keys.id == recipient?.id
                            let recipients = await queryAWSUsers(where: recipientPredicate)
                            if recipients.count >= 1 {
                                recipient = recipients[0]
                            }
                            if let currentUser = currentUser, let recipient = recipient {
                                messages = await queryConversation(sender: currentUser,
                                                                   recipient: recipient)
                            } else {
                                print("Error fetching users")
                            }
                        }
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
                unsubscribeFromConversation()
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
}
