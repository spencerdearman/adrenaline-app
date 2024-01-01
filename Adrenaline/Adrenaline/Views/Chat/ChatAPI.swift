//
//  ChatAPI.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/7/23.
//

import SwiftUI
import Foundation
import Amplify
import Combine

func didTapSend(message: String, sender: NewUser, recipient: NewUser) {
    Task {
        do {
            let message = Message(body: message, creationDate: .now())
            
            let tempSender = MessageNewUser(isSender: true,
                                            newuserID: sender.id,
                                            messageID: message.id)
            let _ = try await Amplify.DataStore.save(tempSender)
            
            let tempRecipient = MessageNewUser(isSender: false,
                                               newuserID: recipient.id,
                                               messageID: message.id)
            let _ = try await Amplify.DataStore.save(tempRecipient)
            
            let savedMessage = try await Amplify.DataStore.save(message)
        } catch {
            print(error)
        }
    }
}

