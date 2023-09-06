//
//  MessagesView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI
import Foundation
import Combine
import Amplify

struct MessagesView: View {
    @State var currentUser: NewUser?
    @State var otherUser: NewUser?
    @State var text: String = ""
    @State var messages: [SentMessage] = []
    
    
//    func queryMessages(where predicate: QueryPredicate? = nil,
//                       sortBy: QuerySortInput? = nil) async -> [Message] {
//        do {
//            let queryResult: [Message] = try await query(where: predicate, sortBy: sortBy)
//            return queryResult
//        } catch let error as DataStoreError {
//            print("Failed to load data from DataStore : \(error)")
//        } catch {
//            print("Unexpected error while calling DataStore : \(error)")
//        }
//        return []
//    }
    
    
    func sendMessage(senderName: String, recipientName: String, body: String,
                     receivedUserID: String, sentUserID: String ) {
        // Create a SentMessage object
        Task {
            do {
                let receivedTempMessage = ReceivedMessage(senderName: senderName,
                                                          body: body,
                                                          creationDate: .now(),
                                                          newuserID: receivedUserID)
                let receivedMessage = try await Amplify.DataStore.save(receivedTempMessage)
                print("ReceivedMessage Created")
                print(receivedMessage.id)
                
                let sentTempMessage = SentMessage(recipientName: recipientName,
                                              body: body,
                                              creationDate: .now(),
                                              SendReceivedMessage: receivedMessage,
                                              newuserID: sentUserID,
                                              sentMessageSendReceivedMessageId: receivedMessage.id)
                let sentMessage = try await Amplify.DataStore.save(sentTempMessage)
                print("SentMessage Created: \(sentMessage)")
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
    
    var body: some View {
        VStack {
//            ScrollView {
//                LazyVStack {
//                    ForEach(messages) { message in
//                        if message.senderName == currentUser {
//                            MessageRow(message: message, isCurrentUser: true)
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        } else {
//                            MessageRow(message: message, isCurrentUser: false)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                    }
//                }
//            }
            
            HStack {
                TextField("Enter message", text: $text)
                    .onChange(of: text) { newText in
                        text = newText
                    }
                Button {
                    sendMessage(senderName: currentUser?.firstName ?? "",
                                recipientName: otherUser?.firstName ?? "",
                                body: text,
                                receivedUserID: otherUser?.id ?? "",
                                sentUserID: currentUser?.id ?? "")

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
                let emailPredicate = NewUser.keys.email != ""
                let users = await queryAWSUsers(where: emailPredicate)
                if users.count > 1 {
                    print(users)
                    currentUser = users[0]
                    otherUser = users[1]
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

//struct MessagesView_Previews: PreviewProvider {
//    static var previews: some View {
//        MessagesView()
//    }
//}
