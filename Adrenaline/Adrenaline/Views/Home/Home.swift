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
    @Environment(\.colorScheme) var currentMode
    @StateObject var meetParser: MeetParser = MeetParser()
    @State private var meetsParsed: Bool = false
    @State private var timedOut: Bool = false
    @State private var selection: ViewType = .upcoming
    
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
    
    @ViewBuilder
    var body: some View {
        NavigationView {
            ZStack {
                HomeColorfulView()
                VStack {
                    VStack {
                        BackgroundBubble(vPadding: 15, hPadding: 30) {
                            Text("Home")
                                .font(.title2).bold()
                        }
                        ZStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .frame(width: typeBubbleWidth * 2 + 5,
                                           height: typeBGWidth)
                                    .foregroundColor(Custom.grayThinMaterial)
                                    .shadow(radius: 5)
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .frame(width: typeBubbleWidth,
                                           height: typeBubbleHeight)
                                    .foregroundColor(Custom.darkGray)
                                    .offset(x: selection == .upcoming
                                            ? -typeBubbleWidth / 2
                                            : typeBubbleWidth / 2)
                                    .animation(.spring(response: 0.2), value: selection)
                                HStack(spacing: 0) {
                                    Button(action: {
                                        if selection == .current {
                                            selection = .upcoming
                                        }
                                    }, label: {
                                        Text(ViewType.upcoming.rawValue)
                                            .animation(nil, value: selection)
                                    })
                                    .frame(width: typeBubbleWidth,
                                           height: typeBubbleHeight)
                                    .foregroundColor(textColor)
                                    .cornerRadius(cornerRadius)
                                    Button(action: {
                                        if selection == .upcoming {
                                            selection = .current
                                        }
                                    }, label: {
                                        Text(ViewType.current.rawValue)
                                            .animation(nil, value: selection)
                                    })
                                    .frame(width: typeBubbleWidth + 2,
                                           height: typeBubbleHeight)
                                    .foregroundColor(textColor)
                                    .cornerRadius(cornerRadius)
                                }
                            }
                            HStack {
                                Spacer()
                                Button(action: {
                                    Task {
                                        await getPresentMeets()
                                    }
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .foregroundColor(Custom.grayThinMaterial)
                                            .shadow(radius: 6)
                                            .frame(width: typeBGWidth, height: typeBGWidth)
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.primary)
                                            .font(.title2)
                                    }
                                })
                            }
                            .padding(.trailing)
                        }
                        .dynamicTypeSize(.xSmall ... .xLarge)
                        
                    }
                    Spacer()
                    if selection == .upcoming {
                        UpcomingMeetsView(meetParser: meetParser, timedOut: $timedOut)
                    } else {
                        CurrentMeetsView(meetParser: meetParser, timedOut: $timedOut)
                    }
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .onSwipeGesture(trigger: .onEnded) { direction in
            if direction == .left && selection == .upcoming {
                selection = .current
            } else if direction == .right && selection == .current {
                selection = .upcoming
            }
        }
        .onAppear {
            Task {
                await getPresentMeets()
            }
        }
    }
}

struct UpcomingMeetsView: View {
    @Environment(\.dictToTuple) private var dictToTuple
    @ObservedObject var meetParser: MeetParser
    @Binding var timedOut: Bool
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
                if isPhone {
                    ScalingScrollView(records: upcoming, bgColor: .clear, rowSpacing: 15,
                                      shadowRadius: 10) { (elem) in
                        MeetBubbleView(elements: elem)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridItems, spacing: 10) {
                            ForEach(upcoming, id: \.self) { elem in
                                MeetBubbleView(elements: elem)
                            }
                        }
                        .padding(20)
                    }
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
            if isPhone {
                ScalingScrollView(records: current, bgColor: .clear, rowSpacing: 15,
                                  shadowRadius: 10) {
                    (elem) in
                    MeetBubbleView(elements: elem)
                }
                                  .padding(.bottom, maxHeightOffset)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 10) {
                        ForEach(current, id: \.self) { elem in
                            MeetBubbleView(elements: elem)
                        }
                    }
                    .padding(20)
                }
            }
        } else if meetParser.currentMeets != nil && !timedOut {
            ZStack{
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .frame(width: 275, height: 75)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 6)
                Text("No current meets found")
            }
            .frame(width: 275, height: 75)
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
    
    private var typeBGColor: Color {
        currentMode == .light ? Custom.background : Custom.background
    }
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
                        
                        ZStack{
                            Rectangle()
                                .fill(Custom.accentThinMaterial)
                                .frame(width: isPhone
                                       ? getPhoneTextSizeForAccessibility()
                                       : getPadTextSizeForAccessibility())
                                .mask(RoundedRectangle(cornerRadius: 30))
                                .shadow(radius: 3)
                            Text(elements[4] + " - " + elements[5]) // startDate - endDate
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
    
    func getPhoneTextSizeForAccessibility() -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 170
        case .small:
            return 180
        case .medium:
            return 190
        case .large:
            return 200
        case .xLarge:
            return 215
        case .xxLarge:
            return 225
        case .xxxLarge:
            return 235
        default:
            return 190
        }
    }
    
    func getPadTextSizeForAccessibility() -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return 180
        case .small:
            return 190
        case .medium:
            return 200
        case .large:
            return 210
        case .xLarge:
            return 220
        case .xxLarge:
            return 240
        case .xxxLarge:
            return 265
        default:
            return 190
        }
    }
}

struct HomeColorfulView: View{
    @Environment(\.colorScheme) var currentMode
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    private var isLandscape: Bool {
        let deviceOrientation = UIDevice.current.orientation
        return deviceOrientation.isLandscape
    }
    
    var body: some View{
        ZStack{
            bgColor.ignoresSafeArea()
            GeometryReader { geometry in
                ZStack{
                    Circle()
                        .stroke(Custom.darkBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 1.1, height: screenWidth * 1.1)
                    
                    Circle()
                        .stroke(Custom.coolBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth, height: screenWidth)
                    
                    Circle()
                        .stroke(Custom.medBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.9, height: screenWidth * 0.9)
                    
                    Circle()
                        .stroke(Custom.lightBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.8, height: screenWidth * 0.8)
                    
                }
                .offset(x: screenWidth / 1.4,
                        y: isPhone
                        ? screenHeight / 15
                        : (!isLandscape
                           ? -screenHeight / 5
                           : -screenHeight))
                
                ZStack{
                    Circle()
                        .stroke(Custom.darkBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 1.1, height: screenWidth * 1.1)
                    
                    Circle()
                        .stroke(Custom.coolBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth, height: screenWidth)
                    
                    Circle()
                        .stroke(Custom.medBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.9, height: screenWidth * 0.9)
                    
                    Circle()
                        .stroke(Custom.lightBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.8, height: screenWidth * 0.8)
                    
                }
                .offset(x: -screenWidth / 2,
                        y: isPhone
                        ? screenHeight / 5
                        : !isLandscape
                        ? screenHeight / 20
                        : -screenHeight / 1.5)
                ZStack{
                    Circle()
                        .stroke(Custom.darkBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 1.1, height: screenWidth * 1.1)
                    
                    Circle()
                        .stroke(Custom.coolBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth, height: screenWidth)
                    
                    Circle()
                        .stroke(Custom.medBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.9, height: screenWidth * 0.9)
                    
                    Circle()
                        .stroke(Custom.lightBlue, lineWidth: screenWidth * 0.023)
                        .frame(width: screenWidth * 0.8, height: screenWidth * 0.8)
                    
                }
                .offset(x: screenWidth / 3, y: screenHeight / 1.5)
            }
        }
    }
}
