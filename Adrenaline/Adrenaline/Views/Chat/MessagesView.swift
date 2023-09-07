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
    
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(messages, id: \.0.id) { message, b in
                        MessageRow(message: message, b: b)
                            .frame(maxWidth: .infinity, alignment: .trailing)
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
                        //                    guard let currentUser = currentUser else { return }
                        didTapSend(message: text, sender: logan, recipient: andrew)
                        print(text)
                        text.removeAll()
                        messages = await queryConversation(sender: andrew, recipient: logan)
                        print(messages)
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
//                let _ = try await saveToDataStore(object: logan)
//                let _ = try await saveToDataStore(object: andrew)
                
                let loganPredicate = NewUser.keys.firstName == "Logan"
                let andrewPredicate = NewUser.keys.firstName == "Andrew"
                let loganUsers = await queryAWSUsers(where: loganPredicate)
                let andrewUsers = await queryAWSUsers(where: andrewPredicate)
            
                if loganUsers.count >= 1 {
                    logan = loganUsers[0]
                    print("logan ")
                    print("worked")
                }
                if andrewUsers.count >= 1 {
                    andrew = andrewUsers[0]
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
