//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI
import Amplify
import Authenticator
import AVKit

// Global timeoutInterval to use for online loading pages
let timeoutInterval: TimeInterval = 30

// Global lock/delay on meet parser to allow time for SwiftUIWebView to access network
// (DiveMeetsConnectorView)
var blockingNetwork: Bool = false

struct ContentView: View {
    @EnvironmentObject var appLogic: AppLogic
    @Environment(\.colorScheme) var currentMode
    @Environment(\.scenePhase) var scenePhase
    @State private var tabBarState: Visibility = .visible
    @AppStorage("signupCompleted") var signupCompleted: Bool = false
    @AppStorage("email") var email: String = ""
    @AppStorage("authUserId") var authUserId: String = ""
    @State var showAccount: Bool = false
    @State var diveMeetsID: String = ""
    @State var newUser: NewUser? = nil
    private let splashDuration: CGFloat = 2
    private let moveSeparation: CGFloat = 0.15
    private let delayToTop: CGFloat = 0.5
    
    var hasHomeButton: Bool {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            guard let window = windowScene?.windows.first else { return false }
            
            return !(window.safeAreaInsets.top > 20)
        }
    }
    
    var menuBarOffset: CGFloat {
        hasHomeButton ? 0 : 20
    }
    
    // Retries getting current user's DiveMeets ID four times in case the user's
    // NewUser hasn't appeared in the DataStore yet.
    //
    // This only seems to require retries on a fresh app launch, since the NewUser table should
    // never be missing their current user in subsequent app launches.
    func getCurrentUserDiveMeetsID(numAttempts: Int = 0) async {
        if numAttempts == 4 { return }
        do {
            // Waits with exponential backoff to give DataStore time to update
            try await Task.sleep(seconds: pow(Double(numAttempts), 2))
            
            let idPredicate = NewUser.keys.id == authUserId
            let users = await queryAWSUsers(where: idPredicate)
            if users.count == 1 {
                newUser = users[0]
                diveMeetsID = newUser?.diveMeetsID ?? ""
            } else {
                print("Failed attempt \(numAttempts + 1) getting DiveMeetsID, retrying...")
                await getCurrentUserDiveMeetsID(numAttempts: numAttempts + 1)
            }
        } catch {
            print("Sleep failed")
        }
    }
    
    var body: some View {
        ZStack {
            if appLogic.initialized {
                Authenticator(
                    signInContent: { state in
                        NewSignIn(state: state, email: $email, authUserId: $authUserId,
                                  signupCompleted: $signupCompleted)
                    }, signUpContent: { state in
                        SignUp(state: state, email: $email, signupCompleted: $signupCompleted)
                    }, confirmSignUpContent: { state in
                        ConfirmSignUp(state: state)
                    }, resetPasswordContent: { state in
                        ForgotPassword(state: state)
                    }, confirmResetPasswordContent: { state in
                        ConfirmPasswordReset(state: state, signupCompleted: $signupCompleted)
                    }
                ) { state in
                    if !signupCompleted {
                        NewSignupSequence(signupCompleted: $signupCompleted, email: $email)
                            .onAppear {
                                Task {
                                    authUserId = state.user.userId
                                    try await Amplify.DataStore.clear()
                                }
                            }
                    } else {
                        TabView {
                            FeedBase(diveMeetsID: $diveMeetsID, showAccount: $showAccount)
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }
                            
                            if let user = newUser, user.accountType != "Spectator" {
                                Chat(email: $email, diveMeetsID: $diveMeetsID, showAccount: $showAccount)
                                    .tabItem {
                                        Label("Chat", systemImage: "message")
                                    }
                            }
                            
                            RankingsView(diveMeetsID: $diveMeetsID, tabBarState: $tabBarState, showAccount: $showAccount)
                                .tabItem {
                                    Label("Rankings", systemImage: "trophy")
                                }
                            
                            Home()
                                .tabItem {
                                    Label("Meets", systemImage: "figure.pool.swim")
                                }
                        }
                        .fullScreenCover(isPresented: $showAccount, content: {
                            NavigationView {
                                // Need to use WrapperView here since we have to pass in state
                                // and showAccount for popover profile
                                if let user = newUser, user.accountType != "Spectator" {
                                    AdrenalineProfileWrapperView(state: state, newUser: user,
                                                                 showAccount: $showAccount)
                                } else if let _ = newUser {
                                    SettingsView(state: state, newUser: newUser,
                                                 showAccount: $showAccount)
                                } else {
                                    // In the event that a NewUser can't be queried, this is the
                                    // default view
                                    AdrenalineProfileWrapperView(state: state,
                                                                 authUserId: authUserId,
                                                                 showAccount: $showAccount)
                                }
                            }
                        })
                        .onAppear {
                            Task {
                                await getCurrentUserDiveMeetsID()
                            }
                        }
                        .ignoresSafeArea(.keyboard)
                    }
                }
            } else {
                Text("Loading")
            }
        }
    }
}
