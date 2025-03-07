//
//  FollowingTestView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import SwiftUI
import Amplify
//
//struct FollowingTestView: View {
//    @State var logan = NewUser(firstName: "Logan", lastName: "Sherwin", 
//                               email: "lsherwin10@gmail.com", accountType: "Athlete")
//    @State var spencer = NewUser(firstName: "Spencer", lastName: "Dearman",
//                                 email: "dearmanspencer@gmail.com", accountType: "Athlete")
//    @State var andrew = NewUser(firstName: "Andrew", lastName: "Chen", email: "achen@gmail.com",
//                                accountType: "Athlete")
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Text("Logan")
//                    .onTapGesture {
//                        Task {
//                            do {
//                                print(logan.favoritesIds)
//                            }
//                        }
//                    }
//                Button(action: {
//                    Task {
//                        await unfollow(follower: spencer, unfollowingId: logan.id)
//                    }
//                }) {
//                    Image(systemName: "delete.left")
//                }
//                Button(action: {
//                    Task {
//                        await follow(follower: spencer, followingId: logan.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.left")
//                }
//                Button(action: {
//                    Task {
//                        await follow(follower: logan, followingId: spencer.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.right")
//                }
//                Button(action: {
//                    Task {
//                        await unfollow(follower: logan,
//                                       unfollowingId: spencer.id)
//                    }
//                }) {
//                    Image(systemName: "delete.right")
//                }
//                Text("Spencer")
//                    .onTapGesture {
//                        Task {
//                            do {
//                                print(spencer.favoritesIds)
//                            }
//                        }
//                    }
//            }
//            HStack {
//                Text("Logan")
//                Button(action: {
//                    Task {
//                        await follow(follower: andrew, followingId: logan.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.left")
//                }
//                Button(action: {
//                    Task {
//                        await follow(follower: logan, followingId: andrew.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.right")
//                }
//                Text("Andrew")
//            }
//            HStack {
//                Text("Spencer")
//                Button(action: {
//                    Task {
//                        await follow(follower: andrew, followingId: spencer.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.left")
//                }
//                Button(action: {
//                    Task {
//                        await follow(follower: spencer, followingId: andrew.id)
//                    }
//                }) {
//                    Image(systemName: "arrow.right")
//                }
//                Text("Andrew")
//            }
//        }
//        .font(.title)
//        .onAppear {
//            Task {
////                print("hello")
////                try await clearLocalDataStore()
//                let users = await queryAWSUsers()
////                print(users)
//                if users.isEmpty {
//                    print("empty")
//                    let _ = try await saveToDataStore(object: logan)
//                    let _ = try await saveToDataStore(object: spencer)
//                    let _ = try await saveToDataStore(object: andrew)
//                } else {
//                    print("not empty")
//                    for user in users {
//                        if user.firstName == "Logan" {
//                            logan = user
//                        } else if user.firstName == "Spencer" {
//                            spencer = user
//                        } else if user.firstName == "Andrew" {
//                            andrew = user
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct FollowingTestView_Previews: PreviewProvider {
//    static var previews: some View {
//        FollowingTestView()
//    }
//}
