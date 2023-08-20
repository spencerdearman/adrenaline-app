//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
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
    @State private var selectedTab: Tab = .house
    @State var showSplash: Bool = false
    @State var authenticated: Bool = false
    private let splashDuration: CGFloat = 2
    private let moveSeparation: CGFloat = 0.15
    private let delayToTop: CGFloat = 0.5
    
    private let theme = AuthenticatorTheme()
    
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
    
    // Necessary to hide gray navigation bar from behind floating tab bar
    init() {
        UITabBar.appearance().isHidden = true
        theme.components.field.cornerRadius = 50
        theme.components.button.primary.cornerRadius = 50
        theme.components.authenticator.spacing.vertical = 15
        theme.colors.background.interactive = Custom.darkBlue
        theme.colors.foreground.primary = Custom.darkBlue
        theme.colors.foreground.secondary = Custom.coolBlue
        theme.colors.foreground.interactive = Custom.coolBlue
    }
    
    var body: some View {
        ZStack {
            // Only shows splash screen while bool is true, auto dismisses after splashDuration
            if showSplash {
                AppLaunchSequence(showSplash: $showSplash)
                    .zIndex(10)
            }
            
            ZStack {
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        HStack {
                            // Add different page views here for different tabs
                            Authenticator { state in
                                switch tab {
                                case .house:
                                    ZStack {
                                        SignOutButton(authenticated: $authenticated)
                                            .onAppear{
                                                Task {
                                                    let session = try await Amplify.Auth.fetchAuthSession()
                                                    if session.isSignedIn {
                                                        authenticated = true
                                                    }
                                                }
                                            }
                                    }
                                    //LandingView()
                                    //Home()
                                case .wrench:
                                    //NavigationView {
                                    //LiveResultsView(request: "debug")
                                    //ToolsMenu()
                                    RankingsView()
                                    //AppLaunchSequence(showSplash: $showSplash)
                                    //UsersDBTestView()
                                case .magnifyingglass:
                                    SearchView()
                                case .person:
                                    AdrenalineLoginView(showSplash: $showSplash)
                                    //LoginSearchView(showSplash: $showSplash)
                                }
                            }
                            .authenticatorTheme(theme)
                        }
                        .tag(tab)
                        
                    }
                }
                if authenticated {
                    FloatingMenuBar(selectedTab: $selectedTab)
                        .offset(y: menuBarOffset)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .dynamicTypeSize(.medium ... .xxxLarge)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            Task {
                let session = try await Amplify.Auth.fetchAuthSession()
                if session.isSignedIn {
                    authenticated = true
                }
            }
        }
    }
}
