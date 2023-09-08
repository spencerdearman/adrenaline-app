//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI
import Amplify
import Authenticator

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
    @State var showAccount: Bool = false
    @State var diveMeetsID: String = ""
    @State var graphUser: GraphUser?
    @State var newAthlete: NewAthlete?
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
    
    var body: some View {
        ZStack {
            if appLogic.initialized {
                Authenticator(
                    signInContent: { state in
                        NewSignIn(state: state, email: $email, signupCompleted: $signupCompleted)
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
                                    try await Amplify.DataStore.clear()
                                }
                            }
                    } else {
                        TabView {
                            FeedBase(diveMeetsID: $diveMeetsID, showAccount: $showAccount)
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }
                                .onAppear{
                                    print(email)
                                }
                            
                            Chat(email: $email, diveMeetsID: $diveMeetsID, showAccount: $showAccount)
                            .tabItem {
                                Label("Chat", systemImage: "message")
                            }
                            
                            RankingsView(tabBarState: $tabBarState)
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
                                AdrenalineProfileView(state: state, email: $email, graphUser: $graphUser, newAthlete: $newAthlete, showAccount: $showAccount)
                            }
                        })
                        .onAppear {
                            Task {
                                let emailPredicate = NewUser.keys.email == email
                                let users = await queryUsers(where: emailPredicate)
                                if users.count >= 1 {
                                    graphUser = users[0]
                                    print(graphUser)
                                    let userPredicate = users[0].athleteId ?? "" == NewAthlete.keys.id.rawValue
                                    let athletes = await queryAWSAthletes(where: userPredicate as? QueryPredicate)
                                    print(athletes)
                                    if athletes.count >= 1 {
                                        newAthlete = athletes[0]
                                        print(newAthlete)
                                    }
                                }
                                diveMeetsID = graphUser?.diveMeetsID ?? ""
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
