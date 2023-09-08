//
//  MessagesView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI
import Foundation
import Amplify

struct MessagesView: View {
    @State var logan = NewUser(firstName: "Logan", lastName: "Sherwin", email: "lsherwin10@gmail.com", accountType: "Athlete")
    @State var andrew = NewUser(firstName: "Andrew", lastName: "Chen", email: "achen@gmail.com", accountType: "Athlete")
    @State var text: String = ""
    @State var messages: [(Message, Bool)] = []
    @Binding var email: String
    @State var currentUser: NewUser?
    @State var recipient: NewUser?
    
    
    var body: some View {
        VStack {
            Text("\(recipient?.firstName ?? "") \(recipient?.lastName ?? "")")
                .fontWeight(.bold)
            ScrollView (showsIndicators: false) {
                LazyVStack {
                    ForEach(messages.sorted(by: { $0.0.createdAt ?? .now() < $1.0.createdAt ?? .now() }), id: \.0.id) { message, b in
                        MessageRow(message: message, b: b)
                            .frame(maxWidth: .infinity, alignment: b ? .trailing : .leading)
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $text)
                    .onChange(of: text) { newText in
                        text = newText
                    }
                Button {
                    Task {
                        //Actual Sending Procedure
                        if let currentUser = currentUser, let recipient = recipient {
                            //                    guard let currentUser = currentUser else { return }
                            didTapSend(message: text, sender: currentUser, recipient: recipient)
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
                            messages = await queryConversation(sender: currentUser, recipient: recipient)
                        } else {
                            print("Error updating the users")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Custom.coolBlue)
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
                let loganPredicate = NewUser.keys.firstName == "Logan"
                let andrewPredicate = NewUser.keys.firstName == "Andrew"
                let loganUsers = await queryAWSUsers(where: loganPredicate)
                let andrewUsers = await queryAWSUsers(where: andrewPredicate)
                if loganUsers.count >= 1 {
                    recipient = loganUsers[0]
                }
                if andrewUsers.count >= 1 {
                    andrew = andrewUsers[0]
                }
                if let currentUser = currentUser, let recipient = recipient {
                    messages = await queryConversation(sender: currentUser, recipient: recipient)
                } else {
                    print("Error fetching users")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
