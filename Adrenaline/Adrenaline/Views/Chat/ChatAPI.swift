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

var conversationSubscription: AmplifyAsyncThrowingSequence<DataStoreQuerySnapshot<Message>>?

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
            startConversationSubscription(matchingIDArray)
            return await queryMessages(withIDs: matchingIDArray, dict: IdDictionary)
        } else {
            print("error with senderMessageNewUsers")
        }
    } catch {
        print("Error: \(error)")
    }
    return []
}

func startConversationSubscription(_ matchingIDArray: [String]) {
    // Create a compound predicate for the list of matching IDs
    var subPredicates: [QueryPredicate] = []
    for messageId in matchingIDArray {
        let idPredicate = Message.keys.id == messageId
        subPredicates.append(idPredicate)
    }
    
    let conversationPredicate = QueryPredicateGroup(type: .or, predicates: subPredicates)
    
    // Subscribe to changes for the matching messages
    conversationSubscription = try? Amplify.DataStore.observeQuery(
        for: Message.self,
        where: conversationPredicate
    )
    
    if let conversationSubscription = conversationSubscription {
        Task {
            do {
                for try await querySnapshot in conversationSubscription {
                    // Handle the updated snapshots as needed
                    print("[Snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")
                }
            } catch {
                print("Error observing conversation: \(error)")
            }
        }
    } else {
        print("conversationSubscription is nil")
    }
}

//func queryConversation(sender: NewUser, recipient: NewUser) async -> [(Message, Bool)] {
//    do {
//        let senderMessageNewUsers = sender.MessageNewUsers
//        let recipientMessageNewUsers = recipient.MessageNewUsers
//        try await senderMessageNewUsers?.fetch()
//        try await recipientMessageNewUsers?.fetch()
//        if let senderMessageNewUsers = senderMessageNewUsers,
//           let recipientMessageNewUsers = recipientMessageNewUsers {
//            let recipientIDSet = Set(recipientMessageNewUsers.map { $0.messageID })
//            let matchingMessages = senderMessageNewUsers.filter { recipientIDSet.contains($0.messageID) }
//            let matchingIDSet = Set(matchingMessages.map { $0.messageID })
//            let matchingIDArray = Array(matchingIDSet)
//            var IdDictionary: [String: Bool] = [:]
//            for m in matchingMessages {
//                IdDictionary[m.messageID] = m.isSender
//            }
//            
//            // Create a compound predicate for the list of matching IDs
//            var subPredicates: [QueryPredicate] = []
//            for messageId in matchingIDArray {
//                let idPredicate = Message.keys.id == messageId
//                subPredicates.append(idPredicate)
//            }
//            
//            let conversationPredicate = QueryPredicateGroup(type: .or, predicates: subPredicates)
//            
//            // Subscribe to changes for the matching messages
//            conversationSubscription = try Amplify.DataStore.observeQuery(
//                for: Message.self,
//                where: conversationPredicate
//            )
//            
//            if let conversationSubscription = conversationSubscription {
//                do {
//                    for try await querySnapshot in conversationSubscription {
//                        // Handle the updated snapshots as needed
//                        print("[Snapshot] item count: \(querySnapshot.items.count), isSynced: \(querySnapshot.isSynced)")
//                    }
//                } catch {
//                    print("Error observing conversation: \(error)")
//                }
//            } else {
//                print("conversationSubscription is nil")
//            }
//            
//            return await queryMessages(withIDs: matchingIDArray, dict: IdDictionary)
//        } else {
//            print("Error with senderMessageNewUsers")
//        }
//    } catch {
//        print("Error: \(error)")
//    }
//    return []
//}

func unsubscribeFromConversation() {
    conversationSubscription?.cancel()
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
        var finalPredicate: QueryPredicate?
        
        for messageID in messageIDs {
            let idPredicate = Message.keys.id == messageID
            if let existingPredicate = finalPredicate {
                // Combining Predicates
                finalPredicate = (idPredicate || existingPredicate)
            } else {
                // For First Predicate
                finalPredicate = idPredicate
            }
        }
        
        if let finalPredicate = finalPredicate {
            let tempMessages = await queryMessages(where: finalPredicate)
            var result: [(Message, Bool)] = []
            for message in tempMessages {
                if let b = dict[message.id] {
                    result.append((message, b))
                }
            }
            return result
        } else {
            return []
        }
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

