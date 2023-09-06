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
    @State var text: String = ""
    @State var messages: [Message] = []
    
    let currentUser = "Spencer"
    
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
    
    func didTapSend(message: String) {
        Task {
            do {
                print(message)
                let message = Message(senderName: currentUser,
                                      body: message,
                                      creationDate: .now())
                let _ = try await Amplify.DataStore.save(message)
                print("Message Saved: \(message)")
                let messagePredicate = Message.keys.senderName == currentUser
                messages = await queryMessages(where: messagePredicate)
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
                        if message.senderName == currentUser {
                            MessageRow(message: message, isCurrentUser: true)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            MessageRow(message: message, isCurrentUser: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $text)
                    .onChange(of: text) { newText in
                        text = newText
                    }
                Button {
                    didTapSend(message: text)
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
                let messagePredicate = Message.keys.senderName == currentUser
                messages = await queryMessages(where: messagePredicate)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
