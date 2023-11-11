//
//  LiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/8/23.
//
//


import SwiftUI
import SwiftSoup
import Amplify

extension String {
    func slice(from: String, to: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(self[rangeFrom..<rangeTo])
    }

    func slice(from: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        return String(self[rangeFrom...])
    }

    func slice(to: String) -> String? {
        guard let rangeTo = self.range(of: to)?.lowerBound else { return nil }
        return String(self[..<rangeTo])
    }
}

//  name, link, last round place, last round total, order, place, total, dive, height, dd,
//score total, [judges scores]
typealias LastDiverInfo = (String, String, Int, Double, Int, Int, Double, String, String, Double,
                           Double, String)

//nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive,
//height, dd, avgScore, maxScore, forFirstPlace
typealias NextDiverInfo = (String, String, Int, Double, Int, String, String, Double, Double,
                           Double, Double)

//                    [[Left to dive, order, last round place, last round score, current place,
//                      current score, name, link, last dive average, event average score,
//                      avg round score]]
typealias DiveTable = [[String]]

typealias BoardDiveTable = [[String]]

struct LiveResultsView: View {
    @Environment(\.dismiss) private var dismiss
    var request: String
    @State var shiftingBool: Bool = false
    let screenFrame = Color(.systemBackground)
    
    var body: some View {
        ZStack {
            ParseLoaderView(request: request, shiftingBool: $shiftingBool)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
        }
    }
}

struct ParseLoaderView: View {
    @Environment(\.colorScheme) var currentMode
    var request: String
    @State var html: String = ""
    @State var rows: [[String: String]] = []
    @State var columns: [String] = []
    @State var focusViewList: [String: Bool] = [:]
    @State private var moveRightLeft = false
    @State private var offset: CGFloat = 0
    @State private var currentViewIndex = 0
    @State private var roundString = ""
    @State private var title: String = ""
    @State var starSelected: Bool = false
    @State var abBoardEvent: Bool = false
    @Binding var shiftingBool: Bool
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    @State var lastDiverInformation: LastDiverInfo = ("", "", 0, 0.0, 0, 0, 0.0, "", "", 0.0, 0.0, "")
    @State var nextDiverInformation: NextDiverInfo = ("", "", 0, 0.0, 0, "", "", 0.0, 0.0, 0.0, 0.0)
    @State var diveTable: DiveTable = []
    @State var boardDiveTable: BoardDiveTable = []
    @State var loadedSuccessfully: Bool = false
    @State private var attemptedLoad: Bool = false
    
    // Shows debug dataset, sets to true if "debug" is request string
    @State private var debugMode: Bool = false
    @State private var timedOut: Bool = false
    
    let screenFrame = Color(.systemBackground)
    private let linkHead = "https://secure.meetcontrol.com/divemeets/system/"
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private func parseLastDiverData(table: Element) -> Bool {
        do {
            var lastDiverName = ""
            var lastDiverProfileLink = ""
            var lastRoundPlace = 0
            var lastRoundTotalScore = 0.0
            var order = 0
            var currentPlace = 0
            var currentTotal = 0.0
            var currentDive = ""
            var height = ""
            var dd = 0.0
            var score = 0.0
            var judgesScores = ""
            
            let lastDiverStr = try table.text()
            let lastDiver = try table.getElementsByTag("a")
            
            if lastDiver.isEmpty() { return false }
            lastDiverName = try lastDiver[0].text()
            
            // Adds space after name and before team
            
            if let idx = lastDiverName.firstIndex(of: "(") {
                lastDiverName.insert(" ", at: idx)
            }
            
            let tempLink = try table.getElementsByTag("a").attr("href")
            lastDiverProfileLink = linkHead + tempLink
            
            lastRoundPlace = Int(lastDiverStr.slice(from: "Last Round Place: ",
                                                    to: " Last Round") ?? "") ?? 0
            lastRoundTotalScore = Double(lastDiverStr.slice(from: "Last Round Total Score: ",
                                                            to: " Diver O") ?? "") ?? 0.0
            order = Int(lastDiverStr.slice(from: "Diver Order: ", to: " Current") ?? "") ?? 0
            currentPlace = Int(lastDiverStr.slice(from: "Current Place: ",
                                                  to: " Current") ?? "") ?? 0
            currentTotal = Double(lastDiverStr.slice(from: "Current Total Score: ",
                                                     to: " Current") ?? "") ?? 0.0
            currentDive = lastDiverStr.slice(from: "Current Dive:   ", to: " Height") ?? ""
            height = lastDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
            dd = Double(lastDiverStr.slice(from: "DD: ", to: " Score") ?? "") ?? 0.0
            score = Double(lastDiverStr.slice(from: String(dd) + " Score: ",
                                              to: " Judges") ?? "") ?? 0.0
            if let lastIndex = lastDiverStr.lastIndex(of: ":") {
                let distance = lastDiverStr.distance(from: lastIndex,
                                                     to: lastDiverStr.endIndex) - 1
                judgesScores = String(lastDiverStr.suffix(distance - 1))
            }
            lastDiverInformation = (lastDiverName, lastDiverProfileLink, lastRoundPlace,
                                    lastRoundTotalScore, order, currentPlace, currentTotal,
                                    currentDive, height, dd, score, judgesScores)
            
            return true
        } catch {
            print("Failed to parse last diver data")
        }
        
        return false
    }
    
    private func parseNextDiverData(table: Element) -> Bool {
        do {
            var lastRoundPlace = 0
            var lastRoundTotalScore = 0.0
            var nextDiverName = ""
            var nextDiverProfileLink = ""
            var nextDive = ""
            var avgScore = 0.0
            var maxScore = 0.0
            var forFirstPlace = 0.0
            var order = 0
            var height = ""
            var dd = 0.0
            
            let upcomingDiverStr = try table.text()
            let nextDiver = try table.getElementsByTag("a")
            
            if nextDiver.isEmpty() { return false }
            nextDiverName = try nextDiver[0].text()
            
            // Adds space after name and before team
            
            if let idx = nextDiverName.firstIndex(of: "(") {
                nextDiverName.insert(" ", at: idx)
            }
            
            let tempLink = try table.getElementsByTag("a").attr("href")
            nextDiverProfileLink = linkHead + tempLink
            
            lastRoundPlace = Int(upcomingDiverStr.slice(from: "Last Round Place: ",
                                                        to: " Last Round") ?? "") ?? 0
            lastRoundTotalScore = Double(upcomingDiverStr.slice(from: "Last Round Total Score: ",
                                                                to: " Diver O") ?? "") ?? 0.0
            order = Int(upcomingDiverStr.slice(from: "Order: ", to: " Next Dive") ?? "") ?? 0
            nextDive = upcomingDiverStr.slice(from: "Next Dive:   ", to: " Height") ?? ""
            height = upcomingDiverStr.slice(from: "Height: ", to: " DD:") ?? ""
            dd = Double(upcomingDiverStr.slice(from: "DD: ", to: " History for") ?? "") ?? 0.0
            avgScore = Double(upcomingDiverStr.slice(from: "Avg Score: ",
                                                     to: "  Max Score") ?? "") ?? 0.0
            maxScore = Double(upcomingDiverStr.slice(from: "Max Score Ever: ",
                                                     to: " Needed") ?? "") ?? 0.0
            var result = ""
            for char in upcomingDiverStr.reversed() {
                if char == " " {
                    break
                }
                result = String(char) + result
            }
            forFirstPlace = Double(result) ?? 999.99
            nextDiverInformation = (nextDiverName, nextDiverProfileLink, lastRoundPlace,
                                    lastRoundTotalScore, order, nextDive, height, dd,
                                    avgScore, maxScore, forFirstPlace)
            
            return true
        } catch {
            print("Failed to parse next diver data")
        }
        
        return false
    }
    
    private func parseCurrentRound(rows: Elements) -> Bool {
        do {
            //Current Round
            
            let currentRound = try rows[8].getElementsByTag("td")
            
            if currentRound.isEmpty() { return false }
            roundString = try currentRound[0].text()
            
            //Diving Table
            
            for (i, t) in rows.enumerated(){
                if i < rows.count - 1 && i >= 10 {
                    var tempList: [String] = []
                    for (i, v) in try t.getElementsByTag("td").enumerated() {
                        if i > 9 { break }
                        if i == 0 {
                            if try v.text() == "" {
                                tempList.append("true")
                            } else {
                                tempList.append("false")
                            }
                        } else if i == 6 {
                            focusViewList[try v.text()] = false
                            tempList.append(try v.text())
                            let halfLink = try v.getElementsByTag("a").attr("href")
                            tempList.append(linkHead + halfLink)
                        } else {
                            tempList.append(try v.text())
                        }
                    }
                    diveTable.append(tempList)
                }
            }
            
            return true
        } catch {
            print("Failed to parse current round")
        }
        
        return false
    }
    
    private func parseABBoardResults(rows: Elements) -> Bool {
        do {
            //Current Round Not Available on Board Pages
            
            //Diving Table
            abBoardEvent = true
            for (i, t) in rows.enumerated(){
                if i < rows.count - 1 && i >= 2 {
                    var tempList: [String] = []
                    for (i, v) in try t.getElementsByTag("td").enumerated() {
                        if i > 10 { break }
                        if i == 1 {
                            tempList.append(try v.text())
                            let halfLink = try v.getElementsByTag("a").attr("href")
                            tempList.append(linkHead + halfLink)
                        } else if i == 2 {
                            tempList.append(try v.text())
                            let halfLink = try v.getElementsByTag("a").attr("href")
                            tempList.append(linkHead + halfLink)
                        } else {
                            tempList.append(try v.text())
                        }
                    }
                    boardDiveTable.append(tempList)
                }
            }
            
            return true
        } catch {
            print("Failed to parse current round")
        }
        return false
    }
    
    private func parseLiveResultsData(newValue: String) async -> Bool {
        let parseTask = Task {
            do {
                let error = ParseError("Failed to parse")
                diveTable = []
                var upperTables: Elements = Elements()
                var individualTables: Elements = Elements()
                let document: Document = try SwiftSoup.parse(newValue)
                guard let body = document.body() else { throw error }
                let table = try body.getElementById("Results")
                guard let rows = try table?.getElementsByTag("tr") else { throw error }
                if rows.count < 2 { throw error }
                if (try rows[1].text().suffix(3) == "Brd") {
                    let _ = parseABBoardResults(rows: rows)
                    //Title
                    title = try rows[0].getElementsByTag("td")[0].text()
                        .replacingOccurrences(of: "Unofficial Statistics ", with: "")
                } else {
                    if rows.count < 9 { throw error }
                    upperTables = try rows[1].getElementsByTag("tbody")
                    
                    if upperTables.isEmpty() { throw error }
                    individualTables = try upperTables[0].getElementsByTag("table")
                    
                    //Title
                    title = try rows[0].getElementsByTag("td")[0].text()
                        .replacingOccurrences(of: "Unofficial Statistics ", with: "")
                    // If not enough tables or last, next, or round parsing fails, throw error
                    if individualTables.count < 3 ||
                        !parseLastDiverData(table: individualTables[0]) ||
                        !parseNextDiverData(table: individualTables[2]) ||
                        !parseCurrentRound(rows: rows) { throw error }
                }
            } catch {
                print("Parsing live event failed")
                try Task.checkCancellation()
                return false
            }
            
            try Task.checkCancellation()
            return true
        }
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeoutInterval) * NSEC_PER_SEC)
            parseTask.cancel()
            timedOut = true
        }
        
        do {
            let result = try await parseTask.value
            timeoutTask.cancel()
            return result
        } catch {
            print("Unable to parse live results page, network timed out")
        }
        
        return false
    }
    
    var body: some View {
        ZStack {
            // Only loads WebView if not in debug mode
            if !debugMode {
                if shiftingBool {
                    LRWebView(request: request, html: $html)
                        .onChange(of: html) {
                            Task {
                                loadedSuccessfully = await parseLiveResultsData(newValue: html)
                                attemptedLoad = true
                            }
                        }
                } else {
                    LRWebView(request: request, html: $html)
                        .onChange(of: html) {
                            Task {
                                loadedSuccessfully = await parseLiveResultsData(newValue: html)
                                attemptedLoad = true
                            }
                        }
                }
            }
            
            bgColor.ignoresSafeArea()
            
            // Loading completed successfully
            if loadedSuccessfully || debugMode {
                LoadedView(lastDiverInformation: $lastDiverInformation, nextDiverInformation:
                            $nextDiverInformation, diveTable: $diveTable,
                           boardDiveTable: $boardDiveTable, focusViewList: $focusViewList,
                           starSelected: $starSelected, shiftingBool: $shiftingBool, title: $title,
                           roundString: $roundString, abBoardEvent: $abBoardEvent)
                // Loading timed out
            } else if timedOut {
                TimedOutView()
                // Attempted load without timing out, but it failed
            } else if attemptedLoad {
                ErrorView()
                // Loading still in progress
            } else {
                LoadingView()
            }
        }
        .onAppear {
            if request == "debug" {
                debugMode = true
            }
            if debugMode {
                lastDiverInformation = DebugDataset.lastDiverInfo
                nextDiverInformation = DebugDataset.nextDiverInfo
                diveTable = DebugDataset.diveTable
                focusViewList = DebugDataset.focusViewDict
                title = DebugDataset.title
                roundString = DebugDataset.roundString
            }
        }
    }
}

struct LoadedView: View {
    @Environment(\.colorScheme) var currentMode
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    //    @State var titleReady: Bool = false
    @Binding var lastDiverInformation:
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    @Binding var nextDiverInformation:
    (String, String, Int, Double, Int, String, String, Double, Double, Double, Double)
    @Binding var diveTable: [[String]]
    @Binding var boardDiveTable: [[String]]
    @Binding var focusViewList: [String: Bool]
    @Binding var starSelected: Bool
    @Binding var shiftingBool: Bool
    @Binding var title: String
    @Binding var roundString: String
    @Binding var abBoardEvent: Bool
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    var colors: [Color] = [.blue, .green, .red, .orange]
    
    func startTimer() {
        
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { timer in
            shiftingBool.toggle()
        }
    }
    
    //    func titleTimer() {
    //        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
    //            titleReady.toggle()
    //        }
    //    }
    
    var body: some View {
        bgColor.ignoresSafeArea()
        ZStack {
            ColorfulView()
            //                .onAppear {
            //                    titleTimer()
            //                }
            GeometryReader { geometry in
                VStack(spacing: 0.5) {
                    if !starSelected {
                        VStack {
                            if abBoardEvent {
                                BackgroundBubble(vPadding: 20, hPadding: 20) {
                                    VStack {
                                        Text(title)
                                            .bold()
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                        Text("Live Rankings")
                                            .bold()
                                    }
                                }
                            } else {
                                BackgroundBubble(vPadding: 20, hPadding: 20) {
                                    VStack {
                                        Text(title)
                                            .bold()
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                        Text(roundString)
                                    }
                                }
                            }
                            
                            if !abBoardEvent {
                                if isPhone {
                                    TileSwapView(
                                        topView: LastDiverView(lastInfo: $lastDiverInformation),
                                        bottomView: NextDiverView(nextInfo: $nextDiverInformation),
                                        width: screenWidth * 0.95,
                                        height: screenHeight * 0.28)
                                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                                } else {
                                    HStack {
                                        Spacer()
                                        LastDiverView(lastInfo: $lastDiverInformation)
                                            .frame(width: screenWidth * 0.45,
                                                   height: screenHeight * 0.2)
                                        Spacer()
                                        NextDiverView(nextInfo: $nextDiverInformation)
                                            .frame(width: screenWidth * 0.45,
                                                   height: screenHeight * 0.2)
                                        Spacer()
                                    }
                                    .offset(y: screenWidth * 0.05)
                                }
                            }
                        }
                    }
                    
                    HomeBubbleView(diveTable: abBoardEvent ? $boardDiveTable : $diveTable,
                                   starSelected: $starSelected, abBoardEvent: $abBoardEvent)
                    .offset(y: abBoardEvent ? screenWidth * 0.03 : screenWidth * 0.1)
                }
                .padding(.bottom, maxHeightOffset)
                .padding(.top)
                .animation(.easeOut(duration: 1), value: starSelected)
                .onAppear {
                    startTimer()
                }
            }
        }
    }
}

struct TimedOutView: View {
    var body: some View {
        BackgroundBubble() {
            Text("Unable to load live results, network timed out")
                .padding()
        }
    }
}

struct ErrorView: View {
    var body: some View {
        BackgroundBubble() {
            Text("Error loading live results")
                .padding()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        BackgroundBubble() {
            VStack {
                Text("Getting live results...")
                ProgressView()
            }
            .padding()
        }
    }
}

struct LastDiverView: View
{
    @Environment(\.colorScheme) var currentMode
    @State private var newUser: NewUser? = nil
    @Binding var lastInfo:
    //  name, link, last round place, last round total, order, place, total, dive, height, dd,
    //score total, [judges scores]
    (String, String, Int, Double, Int, Int, Double, String, String, Double, Double, String)
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var profileLink: String {
        lastInfo.1
    }
    
    private var diveMeetsId: String {
        guard let last = profileLink.split(separator: "=").last else { return "" }
        return String(last)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(50)
                .shadow(radius: 20)
            
            
            VStack(spacing: 5) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Last Diver")
                            .font(.title3).fontWeight(.semibold)
                        Text(lastInfo.0)
                            .font(.title2).bold()
                        Text("Last Round Place: " + (lastInfo.2 == 0 ? "N/A" : String(lastInfo.2)))
                        HStack {
                            Text("Order: " + String(lastInfo.4))
                            Text("Place: " + String(lastInfo.5))
                        }
                        Text("Current Total: " + String(lastInfo.6))
                            .font(.headline)
                    }
                    Spacer().frame(width: 55)
                    
                    if let diver = newUser {
                        NavigationLink {
                            AdrenalineProfileView(newUser: diver)
                        } label: {
                            miniProfileImage
                        }
                    } else {
                        miniProfileImage
                    }
                }
                .padding(.top, 20)
                .dynamicTypeSize(.xSmall ... .xxxLarge)
                .padding([.leading, .trailing])
                
                Spacer()
                
                ZStack {
                    Rectangle()
                        .foregroundColor(Custom.accentThinMaterial)
                        .frame(height: screenHeight * 0.1)
                        .mask(RoundedRectangle(cornerRadius: 50))
                    HStack {
                        VStack {
                            Text(lastInfo.7.components(separatedBy: " - ").first ?? "")
                                .font(.title2)
                                .bold()
                                .scaledToFill()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        VStack {
                            Text(lastInfo.7.components(separatedBy: " - ").last ?? "")
                                .font(.title3)
                                .bold()
                                .scaledToFill()
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            HStack {
                                Text("Height: " + lastInfo.8)
                                Text("DD: " + String(lastInfo.9))
                                Text("Score Total: " + String(lastInfo.10))
                            }
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                            Text(lastInfo.11)
                                .font(.headline)
                        }
                    }
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .scaledToFit()
                    .padding()
                }
                .offset(y: screenHeight * 0.012)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            if newUser == nil {
                Task {
                    let pred = NewUser.keys.diveMeetsID == diveMeetsId
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        newUser = users[0]
                    }
                }
            }
        }
    }
    
    var miniProfileImage: some View {
        MiniProfileImage(
            diverID: String(lastInfo.1.components(separatedBy: "=").last ?? "")
        )
        .scaledToFit()
    }
}

struct NextDiverView: View
{
    @Environment(\.colorScheme) var currentMode
    @State var tableData: [String: DiveData]?
    @State private var newUser: NewUser? = nil
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @Binding var nextInfo: NextDiverInfo
    @State var diveTitle: String = ""
    
    func getSecondSpaceString(s: String) -> String {
        let components = s.split(separator: " ")
        if components.count >= 3 {
            return components[2...].joined(separator: " ")
        } else {
            return s
        }
    }
    
    private var profileLink: String {
        nextInfo.1
    }
    
    private var diveMeetsId: String {
        guard let last = profileLink.split(separator: "=").last else { return "" }
        return String(last)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Custom.darkGray)
                .cornerRadius(50)
                .shadow(radius: 20)
            
            
            //Upper Part
            VStack(spacing: 5) {
                HStack{
                    VStack(alignment: .leading) {
                        Text("Next Diver")
                            .font(.title3).fontWeight(.semibold)
                        Text(nextInfo.0)
                            .font(.title2).bold()
                        Text("Last Round Place: " + (nextInfo.2 == 0 ? "N/A" : String(nextInfo.2)))
                        HStack {
                            Text("Order: " + String(nextInfo.4))
                            Text("For 1st: " + String(nextInfo.10))
                        }
                        Text("Last Round Total: " + String(nextInfo.3))
                            .fontWeight(.semibold)
                    }
                    Spacer().frame(width: 35)
                    
                    let img = MiniProfileImage(
                        diverID: String(nextInfo.1.components(separatedBy: "=").last ?? "")
                    )
                        .scaledToFit()
                    
                    if let diver = newUser {
                        NavigationLink {
                            AdrenalineProfileView(newUser: diver)
                        } label: {
                            img
                        }
                    } else {
                        img
                    }
                }
                .padding(.top, 20)
                .dynamicTypeSize(.xSmall ... .xxxLarge)
                .padding([.leading, .trailing])
                
                Spacer()
                
                //Lower Part
                ZStack {
                    Rectangle()
                        .frame(height: screenHeight * 0.1)
                        .foregroundColor(Custom.accentThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 50))
                    HStack {
                        Text(nextInfo.5.prefix(5))
                            .font(.title2)
                            .bold()
                            .scaledToFill()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        VStack {
                            Text(nextInfo.5.components(separatedBy: " - ").last ?? "")
                                .font(.title3)
                                .bold()
                                .scaledToFill()
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            HStack {
                                Text("Height: " + nextInfo.6)
                                Text("DD: " + String(nextInfo.7))
                            }
                            HStack {
                                Text("Avg. Score: " + String(nextInfo.8))
                                Text("Max Score: " + String(nextInfo.9))
                            }
                            .scaledToFit()
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        }
                    }
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .scaledToFit()
                    .padding()
                }
                .offset(y: screenHeight * 0.012)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            tableData = getDiveTableData()
            
            if newUser == nil {
                Task {
                    let pred = NewUser.keys.diveMeetsID == diveMeetsId
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        newUser = users[0]
                    }
                }
            }
        }
    }
}


struct DebugDataset {
    //  name, link, last round place, last round total, order, place, total, dive, height, dd,
    //score total, [judges scores]
    static let lastDiverInfo: LastDiverInfo =
    ("Diver 1", "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961", 1,
     225.00, 1, 1, 175.00, "5337D - Reverse 1 1/2 Somersaults 3 1/2 Twist Free", "3M", 3.3, 69.3,
     "7.0 | 7.0 | 7.0")
    //nextDiverName, nextDiverProfileLink, lastRoundPlace, lastRoundTotalScore, order, nextDive,
    //height, dd, avgScore, maxScore, forFirstPlace
    static let nextDiverInfo: NextDiverInfo =
    ("Diver 2", "https://secure.meetcontrol.com/divemeets/system/profile.php?number=51197", 3,
     155.75, 2, "307C", "3M", 3.5, 55.0, 105.0, 69.25)
    
    //                    [[Left to dive, order, last round place, last round score, current place,
    //                      current score, name, link, last dive average, event average score, avg round score]]
    static let diver1: [String] = ["true", "1", "1", "175.00", "1", "225.00", "Spencer Dearman",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=51197",
                                   "7.0", "6.5", "55.5"]
    static let diver2: [String] = ["false", "2", "3", "155.75", "3", "155.75", "Diver 2",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "6.0", "5.7", "41.7"]
    static let diver3: [String] = ["false", "3", "2", "158.20", "2", "158.20", "Diver 3",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "6.5", "6.1", "45.3"]
    static let diver4: [String] = ["false", "4", "4", "111.65", "4", "111.65", "Diver 4",
                                   "https://secure.meetcontrol.com/divemeets/system/profile.php?number=56961",
                                   "4.5", "4.8", "37.4"]
    
    static let diveTable: DiveTable = [diver1, diver3, diver2, diver4]
    static let focusViewDict: [String: Bool] = [diver1[6]: false, diver2[6]: false,
                                                diver3[6]: false, diver4[6]: false]
    static let title: String = "Debug Live Results View"
    static let roundString: String = "Round: 3 / 6"
}


struct ColorfulView: View {
    @Environment(\.colorScheme) var currentMode
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    private var isLandscape: Bool {
        let deviceOrientation = UIDevice.current.orientation
        return deviceOrientation.isLandscape
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Custom.darkBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 1.1, height: screenWidth * 1.1)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.coolBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth, height: screenWidth)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.medBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 0.9, height: screenWidth * 0.9)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.lightBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 0.8, height: screenWidth * 0.8)
                    .clipped().ignoresSafeArea()
            }
            .offset(x: isPhone
                    ? screenWidth / 1.9
                    : (!isLandscape
                       ? screenWidth / 1.9
                       : screenWidth * 0.5),
                    y: isPhone
                    ? -screenHeight / 10
                    : (!isLandscape
                       ? screenHeight * 0.4
                       : screenHeight * 0.3))
            
            ZStack {
                Circle()
                    .stroke(Custom.darkBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 1.1, height: screenWidth * 1.1)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.coolBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth, height: screenWidth)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.medBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 0.9, height: screenWidth * 0.9)
                    .clipped().ignoresSafeArea()
                Circle()
                    .stroke(Custom.lightBlue, lineWidth: screenWidth * 0.023)
                    .frame(width: screenWidth * 0.8, height: screenWidth * 0.8)
                    .clipped().ignoresSafeArea()
            }
            .offset(x: isPhone
                    ? -screenWidth / 2
                    : (!isLandscape
                       ? -screenWidth / 2
                       : -screenWidth / 2),
                    y: isPhone
                    ? -screenHeight / 2.5
                    : (!isLandscape
                       ? -screenHeight * 0.3
                       : -screenHeight * 0.8))
        }
    }
}
