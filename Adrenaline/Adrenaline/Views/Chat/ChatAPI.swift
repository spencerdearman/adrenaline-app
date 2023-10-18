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


func queryConversation(sender: NewUser, recipient: NewUser) async -> [(Message, Bool)]  {
    do {
        let senderMessageNewUsers = sender.MessageNewUsers
        let recipientMessageNewUsers = recipient.MessageNewUsers
        try await senderMessageNewUsers?.fetch()
        try await recipientMessageNewUsers?.fetch()
        if let senderMessageNewUsers = senderMessageNewUsers,
           let recipientMessageNewUsers = recipientMessageNewUsers {
            let recipientIDSet = Set(recipientMessageNewUsers.map { $0.messageID })
            let matchingMessages = senderMessageNewUsers.filter {recipientIDSet.contains($0.messageID)}
            let matchingIDSet = Set(matchingMessages.map { $0.messageID })
            let matchingIDArray = Array(matchingIDSet)
            var IdDictionary: [String : Bool] = [:]
            for m in matchingMessages {
                IdDictionary[m.messageID] = m.isSender
            }
            return await queryMessages(withIDs: matchingIDArray, dict: IdDictionary)
        } else {
            print("error with senderMessageNewUsers")
        }
    } catch {
        print("Error: \(error)")
    }
    return []
}



func queryMessageNewUsers(where predicate: QueryPredicate? = nil,
                          sortBy: QuerySortInput? = nil) async -> [MessageNewUser] {
    do {
        let queryResult: [MessageNewUser] = try await query(where: predicate, sortBy: sortBy)
        return queryResult
    } catch let error as DataStoreError {
        print("Failed to load data from DataStore : \(error)")
    } catch {
        print("Unexpected error while calling DataStore : \(error)")
    }
    return []
}

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


func queryMessages(withIDs messageIDs: [String], dict: [String : Bool]) async -> [(Message, Bool)] {
    do {
        var idPredicates: [QueryPredicate] = []
        
        for messageID in messageIDs {
            let idPredicate = QueryPredicateOperation(field: "id", operator: .equals(messageID))
                idPredicates.append(idPredicate)
        }
        let finalPredicate = QueryPredicateGroup(type: .or, predicates: idPredicates)
        let tempMessages = await queryMessages(where: finalPredicate)
        var result: [(Message, Bool)] = []
        for message in tempMessages {
            if let b = dict[message.id] {
                result.append((message, b))
            }
        }
        return result
    }
}


func didTapSend(message: String, sender: NewUser, recipient: NewUser) {
    Task {
        do {
            let message = Message(body: message, creationDate: .now())
            let savedMessage = try await Amplify.DataStore.save(message)
            
            let tempSender = MessageNewUser(isSender: true,
                                            newuserID: sender.id,
                                            messageID: savedMessage.id)
            let _ = try await Amplify.DataStore.save(tempSender)
            
            let tempRecipient = MessageNewUser(isSender: false,
                                               newuserID: recipient.id,
                                               messageID: savedMessage.id)
            let _ = try await Amplify.DataStore.save(tempRecipient)
        } catch {
            print(error)
        }
    }
}

