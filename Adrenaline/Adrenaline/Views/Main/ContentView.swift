//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI

// Global timeoutInterval to use for online loading pages
let timeoutInterval: TimeInterval = 30

struct ContentView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.meetsDB) var db
    @EnvironmentObject private var p: MeetParser
    @State private var selectedTab: Tab = .wrench
    @State var isIndexingMeets: Bool = false
    @State var showSplash: Bool = false
    @FetchRequest(sortDescriptors: []) private var meets: FetchedResults<DivingMeet>
    
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
                MovingSplashView(startDelay: splashDuration, moveSeparation: moveSeparation,
                                 delayToTop: delayToTop)
                .onAppear {
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + splashDuration + moveSeparation * 3 + delayToTop + 0.2) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                }
            }
            
            ZStack {
                VStack {
                    TabView(selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.rawValue) { tab in
                            HStack {
                                // Add different page views here for different tabs
                                switch tab {
                                    case .house:
                                        Home()
                                    case .wrench:
                                        //NavigationView {
                                            //LiveResultsView(request: "debug")
//                                            FinishedLiveResultsView(link: "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-9050-770-9-Finished")
                                        //}
                                        //.navigationViewStyle(StackNavigationViewStyle())
//                                        ToolsMenu()
                                         //SearchColorfulView()
                                        FirstOpenView()
                                    case .magnifyingglass:
                                        SearchView(isIndexingMeets: $isIndexingMeets)
                                    case .person:
                                        LoginSearchView()
                                }
                            }
                            .tag(tab)
                            
                        }
                    }
                }
                
                FloatingMenuBar(selectedTab: $selectedTab)
                    .offset(y: menuBarOffset)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .dynamicTypeSize(.medium ... .xxxLarge)
            }
            .ignoresSafeArea(.keyboard)
            // Executes on app launch
            .onAppear {
                // isIndexingMeets is set to false by default so it is only executed from start
                //     to finish one time (allows indexing to occur in the background without
                //     starting over)
                if !isIndexingMeets {
                    isIndexingMeets = true
                    
                    // Runs this task asynchronously so rest of app can function while this finishes
                    Task {
                        await SkillRating(diveStatistics: nil).testMetrics(0)
                        
                        // This sets p's upcoming, current, and past meets fields
                        try await p.parseMeets(storedMeets: meets)
                        
                        // Check that each set of meets is not nil and add each to the database
                        if let upcoming = p.upcomingMeets {
                            db.addRecords(records: db.dictToTuple(dict: upcoming), type: .upcoming)
                        }
                        if let current = p.currentMeets {
                            db.addRecords(records: db.dictToTuple(dict: current), type: .current)
                        }
                        if let past = p.pastMeets {
                            db.addRecords(records: db.dictToTuple(dict: past), type: .past)
                        }
                        
                        isIndexingMeets = false
                    }
                }
            }
            // Executes when other views are opened (notification center, control center, swiped up)
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    GlobalCaches.loadAllCaches()
                } else if scenePhase == .active && newPhase == .inactive {
                    GlobalCaches.saveAllCaches()
                }
            }
        }
    }
}
