//
//  Home.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/25/23.
//

import SwiftUI

enum ViewType: String, CaseIterable {
    case upcoming = "Upcoming"
    case current = "Current"
}

enum CurrentMeetPageType: String, CaseIterable {
    case info = "Info"
    case results = "Results"
}

// converts MeetRecord tuples to 2d list of Strings for views
func tupleToList(tuples: [MeetRecord]) -> [[String]] {
    var result: [[String]] = []
    //  (id, name, org, link, startDate, endDate, city, state, country)
    for (id, name, org, link, startDate, endDate, city, state, country) in tuples.sorted(
        by: { (lhs, rhs) in
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            
            // Sorts first by start date, then end date, then name in that order
            if lhs.4 == rhs.4 {
                if lhs.5 == rhs.5 {
                    return lhs.1 ?? "" < rhs.1 ?? ""
                }
                
                if let a = lhs.5, let b = rhs.5,
                   let date1 = df.date(from: a), let date2 = df.date(from: b) {
                    return date1 < date2
                }
            }
            
            if let a = lhs.4, let b = rhs.4,
               let date1 = df.date(from: a), let date2 = df.date(from: b) {
                return date1 < date2
            }
            
            return false
        }) {
        let idStr = id != nil ? String(id!) : ""
        result.append([idStr, name ?? "", org ?? "", link ?? "",
                       startDate ?? "", endDate ?? "", city ?? "", state ?? "", country ?? ""])
    }
    return result
}

// Converts MeetRecord tuples with additional results link to 2d list of Strings for views
func tupleToList(tuples: CurrentMeetRecords) -> [[String]] {
    var result: [[String]] = []
    //  (id, name, org, link, startDate, endDate, city, state, country, resultsLink?)
    for ((id, name, org, link, startDate, endDate, city, state, country), resultsLink) in tuples.sorted(
        by: { (lhs, rhs) in
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            
            // Sorts first by start date, then end date, then name in that order
            if lhs.0.4 == rhs.0.4 {
                if lhs.0.5 == rhs.0.5 {
                    return lhs.0.1! < rhs.0.1!
                }
                
                let a = lhs.0.5!
                let b = rhs.0.5!
                
                return df.date(from: a)! < df.date(from: b)!
            }
            
            let a = lhs.0.4!
            let b = rhs.0.4!
            
            return df.date(from: a)! < df.date(from: b)!
        }) {
        let idStr = id != nil ? String(id!) : ""
        result.append([idStr, name ?? "", org ?? "", link ?? "",
                       startDate ?? "", endDate ?? "", city ?? "", state ?? "", country ?? "",
                       resultsLink ?? ""])
    }
    return result
}

struct Home: View {
    @Namespace var namespace
    @Environment(\.colorScheme) var currentMode
//    @Environment(\.dictToTuple) private var dictToTuple
    @Environment(\.networkIsConnected) private var networkIsConnected
    @StateObject var meetParser: MeetParser = MeetParser()
    @State private var meetsParsed: Bool = false
    @State private var timedOut: Bool = false
    @State private var selection: ViewType = .upcoming
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @State private var showTab: Bool = true
    @State private var showNav: Bool = true
    @State private var showStatusBar = true
    @State private var showDetail: Bool = false
    @State private var upcomingFeedItems: [FeedItem] = []
    @State private var currentFeedItems: [FeedItem] = []
    @State private var diveMeetsID: String = ""
    @State private var upcomingItemsLoaded: Bool = false
    @State private var currentItemsLoaded: Bool = false
    @Binding var newUser: NewUser?
    @Binding var tabBarState: Visibility
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 300), spacing: 20),
                                count: UIDevice.current.userInterfaceIdiom == .pad ? 3 : 1)
    
    @ScaledMetric private var typeBubbleWidthScaled: CGFloat = 110
    @ScaledMetric private var typeBubbleHeightScaled: CGFloat = 35
    @ScaledMetric private var typeBGWidthScaled: CGFloat = 40
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var typeBubbleWidth: CGFloat {
        min(typeBubbleWidthScaled, 150)
    }
    private var typeBubbleHeight: CGFloat {
        min(typeBubbleHeightScaled, 48)
    }
    private var typeBGWidth: CGFloat {
        min(typeBGWidthScaled, 55)
    }
    
    private var typeBGColor: Color {
        currentMode == .light ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    private var typeBubbleColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    // Gets present meets from meet parser if false, else clears the fields and runs again
    private func getPresentMeets() async {
        if !meetsParsed {
            let parseTask = Task {
                try await meetParser.parsePresentMeets()
                try Task.checkCancellation()
                meetsParsed = true
            }
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeoutInterval) * NSEC_PER_SEC)
                parseTask.cancel()
                timedOut = true
            }
            
            do {
                try await parseTask.value
                timeoutTask.cancel()
            } catch {
                print("Failed to get present meets, network timed out")
            }
        } else {
            meetParser.upcomingMeets = nil
            meetParser.currentMeets = nil
            meetsParsed = false
            await getPresentMeets()
        }
    }
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private func loadUpcomingMeets() {
        upcomingFeedItems = []
        if let meets = meetParser.upcomingMeets {
            if !meets.isEmpty && !timedOut {
                let upcoming = tupleToList(tuples: dictToTuple(meets))
                for elem in upcoming {
                    upcomingFeedItems.append(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3]), namespace: namespace, feedModel: $feedModel))
                }
            }
            upcomingItemsLoaded = true
        }
    }
    
    private func loadCurrentMeets() {
        currentFeedItems = []
        if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
            let current = tupleToList(tuples: dictToCurrentTuple(dict: meetParser.currentMeets ?? []))
            for elem in current {
                currentFeedItems.append(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3], resultsLink: elem[9]), namespace: namespace, feedModel: $feedModel))
            }
            currentItemsLoaded = true
        }
    }
    
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { offset in
            withAnimation(.easeInOut) {
                if offset < 0 {
                    contentHasScrolled = true
                } else {
                    contentHasScrolled = false
                }
            }
        }
    }
    
    @ViewBuilder
    var body: some View {
        if networkIsConnected {
            NavigationView {
                ZStack {
                    (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
                    
                    if feedModel.showTile {
                        if selection == .current {
                            ForEach($currentFeedItems) { item in
                                if item.id == feedModel.selectedItem {
                                    AnyView(item.expandedView.wrappedValue)
                                }
                            }
                        } else {
                            ForEach($upcomingFeedItems) { item in
                                if item.id == feedModel.selectedItem {
                                    AnyView(item.expandedView.wrappedValue)
                                }
                            }
                        }
                    }
                    
                    if networkIsConnected {
                        ScrollView {
                            scrollDetection
                            
                            Rectangle()
                                .fill(.clear)
                                .frame(height: screenHeight * 0.15)
                            
                            if selection == .current {
                                if showDetail {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach($currentFeedItems) { _ in
                                            Rectangle()
                                                .fill(.white)
                                                .cornerRadius(30)
                                                .shadow(radius: 20)
                                                .opacity(0.3)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .offset(y: -100)
                                } else {
                                    if currentFeedItems != [] && currentItemsLoaded {
                                        LazyVGrid(columns: columns, spacing: 15) {
                                            ForEach($currentFeedItems) { item in
                                                AnyView(item.collapsedView.wrappedValue)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .offset(y: -80)
                                    } else if currentItemsLoaded && currentFeedItems == [] {
                                        Text("Unable to get current meets, network timed out")
                                            .dynamicTypeSize(.xSmall ... .xxxLarge)
                                            .padding()
                                            .multilineTextAlignment(.center)
                                            .frame(width: screenWidth * 0.9)
                                    } else {
                                        VStack {
                                            Text("Getting current meets")
                                                .dynamicTypeSize(.xSmall ... .xxxLarge)
                                            ProgressView()
                                        }
                                    }
                                }
                            } else {
                                if showDetail {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach($upcomingFeedItems) { _ in
                                            Rectangle()
                                                .fill(.white)
                                                .cornerRadius(30)
                                                .shadow(radius: 20)
                                                .opacity(0.3)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .offset(y: -100)
                                } else {
                                    if upcomingFeedItems != [] {
                                        LazyVGrid(columns: columns, spacing: 15) {
                                            ForEach($upcomingFeedItems) { item in
                                                AnyView(item.collapsedView.wrappedValue)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .offset(y: -80)
                                    } else if upcomingItemsLoaded && upcomingFeedItems == [] {
                                        Text("Unable to get upcoming meets, network timed out")
                                            .dynamicTypeSize(.xSmall ... .xxxLarge)
                                            .padding()
                                            .multilineTextAlignment(.center)
                                            .frame(width: screenWidth * 0.9)
                                    } else {
                                        VStack {
                                            Text("Getting upcoming meets")
                                                .dynamicTypeSize(.xSmall ... .xxxLarge)
                                            ProgressView()
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        NotConnectedView()
                    }
                }
                .onAppear {
                    diveMeetsID = newUser?.diveMeetsID ?? ""
                }
                .overlay {
                    if feedModel.showTab {
                        MeetsBar(title: "Meets", diveMeetsID: $diveMeetsID, selection: $selection, showAccount: $showAccount, contentHasScrolled: $contentHasScrolled, feedModel: $feedModel, recentSearches: $recentSearches, uploadingPost: $uploadingPost)
                            .frame(width: screenWidth)
                    }
                }
                .onChange(of: feedModel.showTile) {
                    withAnimation {
                        feedModel.showTab.toggle()
                        showNav.toggle()
                        showStatusBar.toggle()
                    }
                }
                .statusBar(hidden: !showStatusBar)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .dynamicTypeSize(.xSmall ... .xxxLarge)
            .onAppear {
                Task {
                    await getPresentMeets()
                    if upcomingFeedItems == [] {
                        loadUpcomingMeets()
                    }
                    if currentFeedItems == [] {
                        loadCurrentMeets()
                    }
                }
            }
        } else {
            NotConnectedView()
        }
    }
}

struct UpcomingMeetsView: View {
    @ObservedObject var meetParser: MeetParser
    @Binding var timedOut: Bool
    @Binding var feedModel: FeedModel
    @Binding var feedItems: [FeedItem]
    let namespace: Namespace.ID
    let gridItems = [GridItem(.adaptive(minimum: 300))]
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    
    var body: some View {
        if let meets = meetParser.upcomingMeets {
            if !meets.isEmpty && !timedOut {
                let upcoming = tupleToList(tuples: dictToTuple(meets))
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 10) {
                        ForEach(upcoming, id: \.self) { elem in
                            AnyView(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3]), namespace: namespace, feedModel: $feedModel).collapsedView)
                                .onAppear {
                                    feedItems.append(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3]), namespace: namespace, feedModel: $feedModel))
                                }
                        }
                    }
                    .padding(20)
                }
            } else {
                BackgroundBubble(cornerRadius: 30, vPadding: 30, hPadding: 50) {
                    Text("No upcoming meets found")
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                }
            }
        } else if !timedOut {
            BackgroundBubble(cornerRadius: 30, vPadding: 30, hPadding: 50) {
                VStack {
                    Text("Getting upcoming meets")
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                    ProgressView()
                }
            }
        } else {
            BackgroundBubble(cornerRadius: 30) {
                Text("Unable to get upcoming meets, network timed out")
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(width: screenWidth * 0.9)
            }
        }
    }
}


struct CurrentMeetsView: View {
    @ObservedObject var meetParser: MeetParser
    let gridItems = [GridItem(.adaptive(minimum: 300))]
    @Binding var timedOut: Bool
    @Binding var feedModel: FeedModel
    @Binding var feedItems: [FeedItem]
    let namespace: Namespace.ID
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
            let current = tupleToList(tuples: dictToCurrentTuple(dict: meetParser.currentMeets ?? []))
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(current, id: \.self) { elem in
                        AnyView(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3], resultsLink: elem[9]), namespace: namespace, feedModel: $feedModel).collapsedView)
                            .onAppear {
                                feedItems.append(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3]), namespace: namespace, feedModel: $feedModel))
                            }
                    }
                }
                .padding(20)
            }
        } else if meetParser.currentMeets != nil && !timedOut {
            BackgroundBubble(cornerRadius: 30, vPadding: 30, hPadding: 50) {
                Text("No current meets found")
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
            }
        } else if !timedOut {
            BackgroundBubble(cornerRadius: 30, vPadding: 30, hPadding: 50) {
                VStack {
                    Text("Getting current meets")
                    ProgressView()
                }
            }
        } else {
            BackgroundBubble(cornerRadius: 30) {
                VStack(alignment: .center) {
                    Text("Unable to get current meets, network timed out")
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(width: screenWidth * 0.9)
                }
            }
        }
    }
}
