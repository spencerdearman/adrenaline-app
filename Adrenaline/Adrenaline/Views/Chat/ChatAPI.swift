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

// Returns a set of user IDs that have sent incoming chat requests to the current user
func separateChatRequests(conversations: ChatConversations, users: [NewUser]) -> Set<String> {
    var result = Set<String>()
    
    for user in users {
        guard let messages = conversations[user.id] else {
            continue
        }
        
        // If only one message is in the list and they aren't the sender, incoming chat request
        if messages.count == 1, !messages[0].1 {
            result.insert(user.id)
        }
    }
    
    return result
}

// Deletes all MessageNewUser and Message entries shared between the two given users
func deleteConversation(between userA: NewUser, and userB: NewUser) async throws {
    // Get linker table entries with userA in them
    let userAPred = MessageNewUser.keys.newuserID == userA.id
    let userAMessageNewUsers: [MessageNewUser] = try await query(where: userAPred)
    
    // Get linker table entries with userB in them
    let userBPred = MessageNewUser.keys.newuserID == userB.id
    let userBMessageNewUsers: [MessageNewUser] = try await query(where: userBPred)
    
    // Gets a set of unique message ids that are associated with the current user
    let userAMessageIds = Set(userAMessageNewUsers.map { $0.messageID })
    
    // Gets a set of unique message ids that are associated with the recipient
    let userBMessageIds = Set(userBMessageNewUsers.map { $0.messageID })
    
    // Gets message IDs that are shared between current user and recipient
    let sharedMessageIds = userAMessageIds.intersection(userBMessageIds)
    
    // Deletes all linker table entries with message ids associated with both users
    // (both linker table entries, one associated with the current user and the other associated
    //  with the recipient)
    for msg in sharedMessageIds {
        let pred = MessageNewUser.keys.messageID == msg
        let msgNewUsers: [MessageNewUser] = try await query(where: pred)
        
        for msgNewUser in msgNewUsers {
            try await deleteFromDataStore(object: msgNewUser)
        }
    }
    
    // Deletes all Message entries if their id was in the linker table and associated with either
    // user
    for msgId in sharedMessageIds {
        try await Amplify.DataStore.delete(Message.self, withId: msgId)
    }
}
