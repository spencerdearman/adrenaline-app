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
    @Environment(\.networkIsConnected) private var networkIsConnected
    @StateObject var meetParser: MeetParser = MeetParser()
    @State private var meetsParsed: Bool = false
    @State private var timedOut: Bool = false
    @State private var selection: ViewType = .upcoming
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @Binding var diveMeetsID: String
    @Binding var tabBarState: Visibility
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private let cornerRadius: CGFloat = 30
    private let textColor: Color = Color.primary
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    @ScaledMetric private var typeBubbleWidthScaled: CGFloat = 110
    @ScaledMetric private var typeBubbleHeightScaled: CGFloat = 35
    @ScaledMetric private var typeBGWidthScaled: CGFloat = 40
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    init(diveMeetsID: Binding<String>, tabBarState: Binding<Visibility>, showAccount: Binding<Bool>, recentSearches: Binding<[SearchItem]>, uploadingPost: Binding<Post?>) {
        self._diveMeetsID = diveMeetsID
        self._tabBarState = tabBarState
        self._showAccount = showAccount
        self._recentSearches = recentSearches
        self._uploadingPost = uploadingPost
    }
    
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
                    
                    if networkIsConnected {
                        ScrollView {
                            scrollDetection
                            
                            Rectangle()
                                .fill(.clear)
                                .frame(height: screenHeight * 0.08)
                            
                            
                            if selection == .upcoming {
                                UpcomingMeetsView(meetParser: meetParser, timedOut: $timedOut, feedModel: $feedModel, namespace: namespace)
                            } else {
                                CurrentMeetsView(meetParser: meetParser, timedOut: $timedOut, feedModel: $feedModel, namespace: namespace)
                            }
                        }
                    } else {
                        NotConnectedView()
                    }
                }
                .overlay (
                    MeetsBar(title: "Meets", diveMeetsID: $diveMeetsID, selection: $selection, showAccount: $showAccount, contentHasScrolled: $contentHasScrolled, feedModel: $feedModel, recentSearches: $recentSearches, uploadingPost: $uploadingPost)
                    .frame(width: screenWidth)
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .dynamicTypeSize(.xSmall ... .xxxLarge)
            .onAppear {
                Task {
                    await getPresentMeets()
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
    let namespace: Namespace.ID
    let gridItems = [GridItem(.adaptive(minimum: 300))]
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    var body: some View {
        if let meets = meetParser.upcomingMeets {
            if !meets.isEmpty && !timedOut {
                let upcoming = tupleToList(tuples: dictToTuple(meets))
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 10) {
                        ForEach(upcoming, id: \.self) { elem in
                            AnyView(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3]), namespace: namespace, feedModel: $feedModel).collapsedView)
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
    let namespace: Namespace.ID
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    var body: some View {
        if meetParser.currentMeets != nil && !meetParser.currentMeets!.isEmpty {
            let current = tupleToList(tuples: dictToCurrentTuple(dict: meetParser.currentMeets ?? []))
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 10) {
                    ForEach(current, id: \.self) { elem in
                        AnyView(MeetFeedItem(meet: MeetBase(name: elem[1], org: elem[2], location: elem[6] + ", " + elem[7], date: getDisplayDateString(start: elem[4], end: elem[5]), link: elem[3], resultsLink: elem[9]), namespace: namespace, feedModel: $feedModel).collapsedView)
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

struct CurrentMeetsPageView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    var infoLink: String
    var resultsLink: String
    
    @State private var selection: CurrentMeetPageType = .info
    private let cornerRadius: CGFloat = 40
    private let textColor: Color = Color.primary
    private let grayValue: CGFloat = 0.90
    private let grayValueDark: CGFloat = 0.10
    @ScaledMetric private var typeBubbleWidth: CGFloat = 110
    @ScaledMetric private var typeBubbleHeight: CGFloat = 35
    @ScaledMetric private var typeBGWidth: CGFloat = 40
    
    private var typeBubbleColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    @ViewBuilder
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack {
                if resultsLink != "" {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth * 2 + 5,
                                   height: typeBGWidth)
                            .foregroundColor(Custom.grayThinMaterial)
                            .shadow(radius: 4)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(Custom.darkGray)
                            .offset(x: selection == .info
                                    ? -typeBubbleWidth / 2
                                    : typeBubbleWidth / 2)
                            .animation(.spring(response: 0.2), value: selection)
                        HStack(spacing: 0) {
                            Button(action: {
                                if selection == .results {
                                    selection = .info
                                }
                            }, label: {
                                Text(CurrentMeetPageType.info.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                            Button(action: {
                                if selection == .info {
                                    selection = .results
                                }
                            }, label: {
                                Text(CurrentMeetPageType.results.rawValue)
                                    .animation(nil, value: selection)
                            })
                            .frame(width: typeBubbleWidth + 2,
                                   height: typeBubbleHeight)
                            .foregroundColor(textColor)
                            .cornerRadius(cornerRadius)
                        }
                    }
                    .zIndex(2)
                    .padding(.top)
                    Spacer()
                }
                
                if selection == .info {
                    MeetPageView(meetLink: infoLink)
                } else {
                    MeetPageView(meetLink: resultsLink)
                }
                Spacer()
            }
        }
        .zIndex(1)
        .onSwipeGesture(trigger: .onEnded) { direction in
            if direction == .left && selection == .info {
                selection = .results
            } else if direction == .right && selection == .results {
                selection = .info
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct MeetBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .pad ? false : true
    }
    
    //  (id, name, org, link, startDate, endDate, city, state, country, resultsLink?)
    //  resultsLink is only for current meets and is "" if no link is available
    private var elements: [String]
    
    init(elements: [String]) {
        self.elements = elements
    }
    
    var body: some View {
        NavigationLink(destination:
                        elements.count == 10
                       ? AnyView(CurrentMeetsPageView(infoLink: elements[3],
                                                      resultsLink: elements[9]))
                       : AnyView(MeetPageView(meetLink: elements[3]))) {
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.darkGray)
                    .cornerRadius(40)
                    .shadow(radius: isPhone ? 0 : 10)
                VStack {
                    VStack {
                        Text(elements[1]) // name
                            .bold()
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(elements[2]) // org
                            .font(.subheadline)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack {
                        ZStack{
                            Text(elements[6] + ", " + elements[7]) // city, state
                                .padding(.leading)
                        }
                        
                        Spacer()
                        
                        BackgroundBubble(vPadding: 8) {
                            Text(getDisplayDateString(start: elements[4], end: elements[5]))
                                .padding([.leading, .trailing], 5)
                        }
                        .padding(.trailing)
                    }
                    .font(.subheadline)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.primary)
                }
                .padding()
            }
        }
    }
}
