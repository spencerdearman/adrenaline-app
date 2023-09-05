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
    @State var text = String()
    @ObservedObject var sot = SourceOfTruth()
    
    let currentUser = "Spencer"
    
    func didTapSend() {
        Task {
            do {
                let message = Message(senderName: currentUser,
                                      body: text,
                                      creationDate: .now())
                let savedMessage = try await Amplify.DataStore.save(message)
                print("Message Saved: \(message)")
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
                    ForEach(sot.messages) { message in
                        MessageRow(message: message, isCurrentUser: message.senderName == currentUser)
                    }
                }
            }
            
            HStack {
                TextField("Enter message", text: $text)
                Button("Send", action: {
                    didTapSend()
                })
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.purple)
            }
        }
        .padding(.horizontal, 16)
    }
}

extension Message: Identifiable {
    
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
