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
                Button(action: {
                    Task {
                        let followed = NewFollowed(email: "lsherwin10@gmail.com")
                        await addFollowedToUser(user: spencer, followed: followed)
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        let followed = NewFollowed(email: "dearmanspencer@gmail.com")
                        await addFollowedToUser(user: logan, followed: followed)
                    }
                }) {
                    Image(systemName: "arrow.right")
                }
                Text("Spencer")
            }
            HStack {
                Text("Logan")
                Button(action: {
                    Task {
                        let followed = NewFollowed(email: "lsherwin10@gmail.com")
                        await addFollowedToUser(user: andrew, followed: followed)
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        let followed = NewFollowed(email: "achen@gmail.com")
                        await addFollowedToUser(user: logan, followed: followed)
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
                        let followed = NewFollowed(email: "dearmanspencer@gmail.com")
                        await addFollowedToUser(user: andrew, followed: followed)
                    }
                }) {
                    Image(systemName: "arrow.left")
                }
                Button(action: {
                    Task {
                        let followed = NewFollowed(email: "achen@gmail.com")
                        await addFollowedToUser(user: spencer, followed: followed)
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
                            try await logan.followed?.fetch()
                            print(logan.followed?.elements)
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
