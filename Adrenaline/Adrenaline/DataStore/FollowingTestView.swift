//
//  FollowingTestView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/31/23.
//

import SwiftUI
import Amplify

struct FollowingTestView: View {
    @State var logan = NewUser(firstName: "Logan", lastName: "Sherwin", email: "lsherwin10@gmail.com", accountType: "Athlete")
    @State var spencer = NewUser(firstName: "Spencer", lastName: "Dearman", email: "dearmanspencer@gmail.com", accountType: "Athlete")
    @State var andrew = NewUser(firstName: "Andrew", lastName: "Chen", email: "achen@gmail.com", accountType: "Athlete")
    
    var body: some View {
        VStack {
            HStack {
                Text("Logan")
                    .onTapGesture {
                        Task {
                            do {
                                if let followed = logan.followed {
                                    try await followed.fetch()
                                    print(followed.elements)
                                } else {
                                    print([String]())
                                }
                            }
                        }
                    }
                Button(action: {
                    Task {
                        await unfollow(follower: spencer, unfollowingEmail: "lsherwin10@gmail.com")
                    }
                }) {
                    Image(systemName: "delete.left")
                }
                Button(action: {
                    Task {
                        await follow(follower: spencer, followingEmail: "lsherwin10@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        await follow(follower: logan, followingEmail: "dearmanspencer@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                Button(action: {
                    Task {
                        await unfollow(follower: logan,
                                       unfollowingEmail: "dearmanspencer@gmail.com")
                    }
                }) {
                    Image(systemName: "delete.right")
                }
                Text("Spencer")
                    .onTapGesture {
                        Task {
                            do {
                                if let followed = spencer.followed {
                                    try await followed.fetch()
                                    print(followed.elements)
                                } else {
                                    print([String]())
                                }
                            }
                        }
                    }
            }
            HStack {
                Text("Logan")
                Button(action: {
                    Task {
                        await follow(follower: andrew, followingEmail: "lsherwin10@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        await follow(follower: logan, followingEmail: "achen@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                Text("Andrew")
            }
            HStack {
                Text("Spencer")
                Button(action: {
                    Task {
                        await follow(follower: andrew, followingEmail: "dearmanspencer@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        await follow(follower: spencer, followingEmail: "achen@gmail.com")
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                Text("Andrew")
            }
        }
        .font(.title)
        .onAppear {
            Task {
//                print("hello")
//                try await clearLocalDataStore()
                let users = await queryUsers()
//                print(users)
                if users.isEmpty {
                    print("empty")
                    let _ = try await saveToDataStore(object: logan)
                    let _ = try await saveToDataStore(object: spencer)
                    let _ = try await saveToDataStore(object: andrew)
                } else {
                    print("not empty")
                    for user in users {
                        if user.firstName == "Logan" {
                            logan = NewUser(from: user)
                        } else if user.firstName == "Spencer" {
                            spencer = NewUser(from: user)
                        } else if user.firstName == "Andrew" {
                            andrew = NewUser(from: user)
                        }
                    }
                }
            }
        }
    }
}

struct FollowingTestView_Previews: PreviewProvider {
    static var previews: some View {
        FollowingTestView()
    }
}
