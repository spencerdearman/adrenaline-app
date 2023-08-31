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
    @State var showSplash: Bool = false
    @State var signupCompleted: Bool = true
    @State var email: String = "dearmanspencer@gmail.com"
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
                        NewSignIn(state: state)
                    }
                ) { state in
                    if !signupCompleted {
                        NewSignupSequence(signupCompleted: $signupCompleted, email: $email)
                    } else {
                        TabView {
                            FeedBase()
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }
                            NavigationView {
                                AdrenalineProfileView(state: state, email: $email)
                            }
                            .tabItem {
                                Label("Rankings", systemImage: "trophy")
                            }
                            
                            VStack {
                                Text("Meets View")
                                Text("**Clear Datastore**")
                                    .onTapGesture {
                                        Task {
                                            try await Amplify.DataStore.clear()
                                        }
                                    }
                            }
                                .tabItem {
                                    Label("Profile", systemImage: "person")
                                }
                            
                            Text("Rankings View")
                                .tabItem {
                                    Label("Search", systemImage: "magnifyingglass")
                                }
                                .onAppear{
                                    Task {
                                        let emailPredicate = NewUser.keys.email == email
                                        let user = await queryUsers(where: emailPredicate)
                                        print(user)
                                        
                                        let userPredicate = user[0].athleteId ?? "" == NewAthlete.keys.id.rawValue
                                        let athlete = await queryAWSAthletes(where: userPredicate as? QueryPredicate)
                                        print(athlete)
                                    }
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
