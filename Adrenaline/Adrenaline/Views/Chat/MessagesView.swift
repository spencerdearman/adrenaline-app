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
    @State var messages: [Message] = []
    @Binding var email: String
    @State var currentUser: NewUser?
    
    
    func queryMessages(where predicate: QueryPredicate? = nil,
                       sortBy: QuerySortInput? = nil) async -> [Message] {
        do {
            let queryResult: [Message] = try await query(where: predicate, sortBy: sortBy)
            return queryResult
        } catch let error as DataStoreError {
            print("Failed to load data from DataStore : \(error)")
        } catch {
            print("Unexpected error while calling DataStore : \(error)")
        }
        return []
    }
    
    func didTapSend(message: String, sender: NewUser, recipient: NewUser) {
        Task {
            do {
                print(message)
                let message = Message(body: message, creationDate: .now())
                let savedMessage = try await Amplify.DataStore.save(message)
                
                let tempSender = MessageNewUser(isSender: true,
                                                newuserID: sender.id,
                                                messageID: savedMessage.id)
                let sender = try await Amplify.DataStore.save(tempSender)
                print("sender: \(sender)")
                
                let tempRecipient = MessageNewUser(isSender: false,
                                                   newuserID: recipient.id,
                                                   messageID: savedMessage.id)
                let recipient = try await Amplify.DataStore.save(tempRecipient)
                print("recipient: \(recipient)")
            } catch {
                print(error)
            }
        }
        print(text)
        text.removeAll()
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
//                        if message.senderName == currentUser {
//                            MessageRow(message: message, isCurrentUser: true)
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        } else {
//                            MessageRow(message: message, isCurrentUser: false)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $text)
                    .onChange(of: text) { newText in
                        text = newText
                    }
                Button {
//                    guard let currentUser = currentUser else { return }
                    didTapSend(message: text, sender: andrew, recipient: logan)
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
