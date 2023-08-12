//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

// Global timeoutInterval to use for online loading pages
let timeoutInterval: TimeInterval = 30

// Global lock/delay on meet parser to allow time for SwiftUIWebView to access network
// (DiveMeetsConnectorView)
var blockingNetwork: Bool = false

struct ContentView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.scenePhase) var scenePhase
//    @EnvironmentObject var userData: UserData
    @State private var selectedTab: Tab = .house
    @State var showSplash: Bool = false
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
    
    // Necessary to hide gray navigation bar from behind floating tab bar
    init() {
        UITabBar.appearance().isHidden = true
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
                            switch tab {
                                case .house:
                                LandingView()
//                                    Home()
                                case .wrench:
                                    //NavigationView {
//                                    LiveResultsView(request: "debug")
                                    //                                            FinishedLiveResultsView(link: "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-9050-770-9-Finished")
                                    //}
                                    //.navigationViewStyle(StackNavigationViewStyle())
                                    //ToolsMenu()
                                    //SearchColorfulView()
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
                        .tag(tab)
                        
                    }
                }
                FloatingMenuBar(selectedTab: $selectedTab)
                    .offset(y: menuBarOffset)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .dynamicTypeSize(.medium ... .xxxLarge)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}
