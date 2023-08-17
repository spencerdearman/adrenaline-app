//
//  LandingView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/11/23.
//

import SwiftUI
import Combine
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin

struct SignOutButton : View {
    @Binding var authenticated: Bool
    @EnvironmentObject var appLogic: AppLogic
    
    var body: some View {
        NavigationLink(destination: LandingView()) {
            Button(action: {
                Task {
                    do {
                        try await appLogic.signOut()
                        authenticated = false
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }) {
                Text("Sign Out")
            }
        }
    }
}

struct LandingView: View {
//    @EnvironmentObject var user: UserData
    @EnvironmentObject var appLogic: AppLogic
    @Environment(\.graphUsers) private var users
    @State private var authenticated: Bool = false
    @State private var image: Image = ImageStore.shared.placeholder()
    
    var body: some View {
        NavigationView {
            VStack {
                if !authenticated {
                    Button(action: {
                        Task {
                            do {
                                try await appLogic.authenticateWithHostedUI()
                                let session = try await Amplify.Auth.fetchAuthSession()
                                if session.isSignedIn {
                                    authenticated = true
                                }
                            } catch {
                                print("Error authenticating: \(error)")
                            }
                        }
                    }) {
                        UserBadge()
                    }
                } else {
                    SignOutButton(authenticated: $authenticated)
                        .onAppear{
                            print("Coming into the signout portion")
                        }
                }
                
                VStack {
                    ForEach(users, id: \.id) { user in
                        HStack {
                            Text(user.firstName)
                            Text(user.lastName)
                            Text(user.email)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                let user = NewUser(firstName: "Andrew", lastName: "Chen", email: "achen@gmail.com", accountType: "Athlete")
                                let savedUser = try await Amplify.DataStore.save(user)
                                print("Saved user: \(savedUser.email)")
                            } catch {
                                print("Could not save user to DataStore: \(error)")
                            }
                        }
                    }) {
                        Text("Create New User")
                    }
                    
                    if image != ImageStore.shared.placeholder() {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .onAppear {
            Task {
                let session = try await Amplify.Auth.fetchAuthSession()
                if session.isSignedIn {
                    authenticated = true
                }
                
                image = await appLogic.imageStore.image(name: "training-trip")
            }
        }
    }
}

