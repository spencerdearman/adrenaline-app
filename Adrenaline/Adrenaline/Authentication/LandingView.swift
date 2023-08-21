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
import AVKit
import PhotosUI

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
    @EnvironmentObject var appLogic: AppLogic
    @Environment(\.graphUsers) private var users
    @Environment(\.videoStore) private var videoStore
    @State private var authenticated: Bool = false
    @State private var video: VideoPlayer<EmptyView>? = nil
    @State private var selection: PhotosPickerItem? = nil
    
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
                        .onAppear {
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
                                let user = GraphUser(firstName: "Andrew", lastName: "Chen", email: "achen@gmail.com", accountType: "Athlete")
                                let savedUser = try await saveUser(user: user)
                            } catch {
                                print("Could not save user to DataStore: \(error)")
                            }
                        }
                    }) {
                        Text("Create New User")
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                try await updateUserField(email: "achen@gmail.com", key: "phone",
                                                          value: "1234567890")
                            } catch {
                                print("Could not update user field: \(error)")
                            }
                        }
                    }) {
                        Text("Update User Field")
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                try await deleteUserByEmail(email: "achen@gmail.com")
                            } catch {
                                print("Could not save user to DataStore: \(error)")
                            }
                        }
                    }) {
                        Text("Delete Last User")
                    }
                    
//                    PhotosPicker("Add Video", selection: $selection,
//                                 matching: .any(of: [.videos, .not(.images)]))
//                    .onChange(of: selection) { newValue in
//                        if newValue == nil { return }
//
//                        var selectedFileData: Data? = nil
//                        Task {
//
//                            if let selection = selection,
//                               let data = try? await selection.loadTransferable(type: Data.self) {
//                                selectedFileData = data
//                            }
//                            guard let type = selection?.supportedContentTypes.first else {
//                                print("There is not supported type")
//                                return
//                            }
//
//                            if let data = selectedFileData,
//                               type.conforms(to: UTType.movie) {
//                                video = nil
//                                video = await videoStore.uploadVideo(data: data,
//                                                                email: "Lsherwin10@gmail.com",
//                                                                              name: "test")
//                                selection = nil
//                            }
//                        }
//                    }
                    
//                    if video != nil {
//                        video
//                    } else {
//                        ProgressView()
//                    }
                }
            }
        }
        .onAppear {
            Task {
                let session = try await Amplify.Auth.fetchAuthSession()
                if session.isSignedIn {
                    authenticated = true
                }
                
//                video = await videoStore.video(email: "lsherwin10@gmail.com", name: "logan-401")
            }
        }
    }
}

