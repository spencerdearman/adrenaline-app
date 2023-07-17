//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import SwiftUI
import SwiftSoup

private enum Stage: Int, CaseIterable {
    case upcoming
    case past
}

struct ParseError: LocalizedError {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
    
    var errorDescription: String? {
        description
    }
}

struct PastMeetEvent {
    var eventName: String
    var eventLink: String
    let columnLabels: [String] = ["Diver", "Team", "Place", "Score", "Diff"]
    // Rows from results ordered by place first->last
    var rows: [[String: String]]
}

struct PastMeetResults {
    var meetName: String
    var meetLink: String
    var events: [PastMeetEvent]
}

//                       (Name ,  Link, startDate, endDate, city, state, country)
typealias MeetDictBody = (String, String, String, String, String, String, String)
//                    Year  :  Org   : [MeetDictBody]
typealias MeetDict = [String: [String: [MeetDictBody]]]
//                              (Link, startDate, endDate, city, state , country)
typealias CurrentMeetDictBody = (String, String, String, String, String, String)
//                           [Name  :  Link Type ("info" or "results") : CurrentMeetDictBody]
//                                   Note: "results" key not always present
typealias CurrentMeetList = [[String: [String: CurrentMeetDictBody]]]
//                           Meet  :  Event : LiveResults object
typealias LiveResultsDict = [String: [String: LiveResults]]


// Decomposes a row's children into a list of strings
func decomposeRow(row: Element) -> [String] {
    var result: [String] = []
    do {
        let children = row.children()
        for child in children {
            result.append(try child.text())
        }
        return result
    } catch {
        print("Decomposing row failed")
        return []
    }
}

// Only used for views, not to be used for database
func dictToCurrentTuple(dict: CurrentMeetList) -> CurrentMeetRecords {
    var result: CurrentMeetRecords = []
    var meetId: Int?
    var meetLink: String?
    var meetStartDate: String?
    var meetEndDate: String?
    var meetCity: String?
    var meetState: String?
    var meetCountry: String?
    var resultsLink: String?
    
    for elem in dict {
        for (name, typeDict) in elem {
            resultsLink = nil
            for (typ, (link, startDate, endDate, city, state, country)) in typeDict {
                if typ == "results" {
                    resultsLink = link
                    continue
                }
                meetId = Int(link.split(separator: "=").last!)!
                meetLink = link
                meetStartDate = startDate
                meetEndDate = endDate
                meetCity = city
                meetState = state
                meetCountry = country
            }
            result.append(
                ((meetId, name, nil, meetLink, meetStartDate, meetEndDate, meetCity, meetState,
                  meetCountry),
                 resultsLink))
        }
    }
    
    return result
}


final class MeetParser: ObservableObject {
    // Upcoming meets happening in the future
    @Published var upcomingMeets: MeetDict?
    // Meets that are actively happening during that time period
    @Published var currentMeets: CurrentMeetList?
    // Current meets that have live results available on their results page
    @Published var liveResults: LiveResultsDict?
    // Meets that have already happened
    @Published var pastMeets: MeetDict?
    @Published var meetsParsedCount: Int = 0
    @Published var totalMeetsParsedCount: Int = 0
    @Published var isFinishedCounting: Bool = false
    private let currentYear = String(Calendar.current.component(.year, from: Date()))
    private var linkText: String?
    private var pastYear: String = ""
    private var stage: Stage?
    private let loader = GetTextAsyncLoader()
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    private var storedPastMeetYears: Set<Int>? = nil
    
    // Gets html text from async loader
    private func fetchLinkText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.linkText = text
        }
    }
    
    // Loads each stored year in the database into a set
    private func pullStoredPastMeetYears(storedMeets: FetchedResults<DivingMeet>) {
        let entries = Array(storedMeets).filter {(m) -> Bool in
            m.startDate != nil
        }
        
        storedPastMeetYears = Set<Int>(entries.map {
            if let startDate = $0.startDate,
                let year = Calendar.current.dateComponents([.year], from: startDate).year {
                return year
            }
            
            return 0
        })
    }
    
    // Gets the list of meet names and links to their pages from an org page
    private func getMeetInfo(text: String) -> [MeetDictBody]? {
        var result: [MeetDictBody] = []
        do {
            let document: Document = try SwiftSoup.parse(text)
            guard let body = document.body() else { return [] }
            guard let content = try body.getElementById("dm_content") else { return [] }
            let trs = try content.getElementsByTag("tr")
            let filtered = trs.filter({ (elem: Element) -> Bool in
                do {
                    let tr = try elem.getElementsByAttribute("bgcolor").text()
                    return tr != ""
                } catch {
                    return false
                }
            })
            
            for meetRow in filtered {
                let fullCols = try meetRow.getElementsByTag("td")
                let cols = fullCols.filter({(col: Element) -> Bool in
                    do {
                        // Filters out the td that contains the logo icon
                        return try !col.hasAttr("align")
                        && col.hasAttr("valign") && col.attr("valign") == "top"
                    } catch {
                        return false
                    }
                })
                
                let meetData = cols[0]
                let startDate = try cols[1].text()
                let endDate = try cols[2].text()
                let city = try cols[3].text()
                let state = try cols[4].text()
                let country = try cols[5].text()
                
                // Gets divs from page (meet name on past meets where link is "Results")
                let divs = try meetData.getElementsByTag("div")
                
                var name: String = try !divs.isEmpty() ? divs[0].text() : ""
                var link: String?
                
                // Gets links from list of meets
                let elem = try meetData.getElementsByTag("a")
                for e in elem {
                    if try e.tagName() == "a"
                        && e.attr("href").starts(with: "meet") {
                        
                        // Gets name from link if meetinfo link, gets name from div if
                        // meetresults link
                        name = try divs.isEmpty() ? e.text() : divs[0].text()
                        link = try leadingLink + e.attr("href")
                        break
                    }
                }
                
                if let link = link {
                    result.append((name, link, startDate, endDate, city, state, country))
                }
            }
            
            return result
        } catch {
            print("Parse failed")
        }
        
        return nil
    }
    
    // Parses current meets from homepage sidebar since "Current" tab is not reliable
    private func parseCurrentMeets(html: String) async {
        var result: CurrentMeetList = []
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return }
            let content = try body.getElementById("dm_content")
            let sidebar = try content?.getElementsByTag("div")[3]
            // Gets table of all current meet rows
            let currentTable = try sidebar?.getElementsByTag("table")
                .first()?.children().first()
            // Gets list of Elements for each current meet
            guard let currentRows = try currentTable?.getElementsByTag("table")  else { return }
            for row in currentRows {
                var resultElem: [String: [String: CurrentMeetDictBody]] = [:]
                let rowRows = try row.getElementsByTag("td")
                
                let meetElem = rowRows[0]
                
                resultElem[try meetElem.text()] = [:]
                
                let infoLink = try leadingLink +
                meetElem.getElementsByAttribute("href")[0].attr("href")
                
                var resultsLink: String? = nil
                
                if rowRows.count > 1 {
                    let meetResults = rowRows[1]
                    do {
                        let resultsLinks = try meetResults.getElementsByAttribute("href")
                        
                        if resultsLinks.count > 0 {
                            resultsLink = try leadingLink + resultsLinks[0].attr("href")
                        }
                    } catch {
                        print("Failed to get link from meet results")
                    }
                }
                
                let meetLoc = try rowRows[2].text()
                guard let commaIdx = meetLoc.firstIndex(of: ",") else { return }
                let city = String(meetLoc[..<commaIdx])
                let state = String(meetLoc[meetLoc.index(commaIdx, offsetBy: 2)...])
                let country = "US"
                
                let meetDates = try rowRows[3].text()
                guard let dashIdx = meetDates.firstIndex(of: "-") else { return }
                guard let yearCommaIdx = meetDates.firstIndex(of: ",") else { return }
                let startDate = String(meetDates[..<dashIdx]
                    .trimmingCharacters(in: .whitespacesAndNewlines))
                + meetDates[yearCommaIdx...]
                let endDate = String(meetDates[meetDates.index(dashIdx, offsetBy: 2)...])
                
                resultElem[try meetElem.text()]!["info"] =
                (infoLink, startDate, endDate, city, state, country)
                
                if let resultsLink = resultsLink {
                    resultElem[try meetElem.text()]!["results"] =
                    (resultsLink, startDate, endDate, city, state, country)
                }
                
                result.append(resultElem)
            }
            
            await MainActor.run { [result] in
                currentMeets = result
            }
            
        } catch {
            print("Parsing current meets failed")
        }
    }
    
    
    // Parses the results page of an event in a past meet's results page
    private func parsePastMeetEventResults(eventName: String,
                                           link: String) async -> PastMeetEvent? {
        guard let url = URL(string: link) else { return nil }
        await getTextModel.fetchText(url: url)
        var tableRows: [[String: String]] = []
        if let text = getTextModel.text {
            do {
                
                let document: Document = try SwiftSoup.parse(text)
                guard let body = document.body() else { return nil }
                let content = try body.getElementById("dm_content")
                let table = try content?.getElementsByTag("table")[0]
                let rows = try table?.getElementsByTag("tr")
                let columnsRow = rows![3]
                let columns = decomposeRow(row: columnsRow)
                
                for (idx, row) in rows!.enumerated() {
                    if idx < 5 || idx == rows!.count - 1 {
                        continue
                    }
                    let rowVals = decomposeRow(row: row)
                    tableRows.append(Dictionary(
                        uniqueKeysWithValues: zip(columns, rowVals)))
                }
                
                return PastMeetEvent(eventName: eventName, eventLink: link, rows: tableRows)
            } catch {
                print("Parsing past meet event results failed")
            }
        } else {
            print("Could not fetch model text")
        }
        return nil
    }
    
    // Parses the events of a past meet's results page
    // Note: This is not implemented in the automatic parsing of the Meets tabs
    // to avoid slow initial parsing times, but this should be called when a
    // meet results page is eventually loaded
    func parsePastMeetResults(meetName: String, link: String
    ) async -> PastMeetResults? {
        guard let url = URL(string: link) else { return nil }
        await getTextModel.fetchText(url: url)
        var events: [PastMeetEvent] = []
        
        if let text = getTextModel.text {
            do {
                events = []
                
                let document: Document = try SwiftSoup.parse(text)
                guard let body = document.body() else { return nil }
                let content = try body.getElementById("dm_content")
                let table = try content?.getElementsByTag("table")[0]
                let rows = try table?.getElementsByAttribute("bgcolor")
                
                for row in rows! {
                    let event = try row.getElementsByTag("td")[0]
                    let eventName = try event.text()
                    let eventLink = try event.getElementsByTag("a")[0].attr("href")
                    
                    if let results = await parsePastMeetEventResults(eventName: eventName,
                                                               link: leadingLink + eventLink) {
                        events.append(results)
                    }
                }
                
                return PastMeetResults(meetName: meetName, meetLink: link, events: events)
            } catch {
                print("Parsing past meet results failed")
            }
        } else {
            print("Could not fetch model text")
        }
        return nil
    }
    
    // Counts the meets to be parsed on a given HTML page
    private func countMeetNames(text: String) -> Int? {
        var count: Int = 0
        do {
            let document: Document = try SwiftSoup.parse(text)
            guard let body = document.body() else { return nil }
            guard let content = try body.getElementById("dm_content") else { return nil }
            let rows = try content.getElementsByTag("td")
            for row in rows {
                // Only continues on rows w/o align field and w valign == top
                if !(try !row.hasAttr("align")
                     && row.hasAttr("valign") && row.attr("valign") == "top") {
                    continue
                }
                
                // Gets links from list of meets
                let elem = try row.getElementsByTag("a")
                for e in elem {
                    if try e.tagName() == "a"
                        && e.attr("href").starts(with: "meet") {
                        count += 1
                        break
                    }
                }
            }
        } catch {
            print("Count failed")
        }
        
        return count
    }
    
    // Counts all of the current meets to be parsed
    private func countCurrentMeets(html: String) async -> Int? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return nil }
            let content = try body.getElementById("dm_content")
            let sidebar = try content?.getElementsByTag("div")[3]
            // Gets table of all current meet rows
            let currentTable = try sidebar?.getElementsByTag("table")
                .first()?.children().first()
            // Gets list of Elements for each current meet
            let currentRows = try currentTable?.getElementsByTag("table")
            if let rows = currentRows {
                return rows.count
            } else {
                return 0
            }
        } catch {
            print("Counting current meets failed")
        }
        
        return nil
    }
    
    // Counts all of the meets to be parsed from the meet parse on launch to provide an accurate
    // indexing progress bar
    private func countParsedMeets(
        html: String, storedMeets: FetchedResults<DivingMeet>? = nil) async throws {
            do {
                let document: Document = try SwiftSoup.parse(html)
                guard let body = document.body() else { return }
                guard let menu = try body.getElementById("dm_menu_centered") else { return }
                let menuTabs = try menu.getElementsByTag("ul")[0].getElementsByTag("li")
                for tab in menuTabs {
                    // tabElem is one of the links from the tabs in the menu bar
                    let tabElem = try tab.getElementsByAttribute("href")[0]
                    if try tabElem.text() == "Find" {
                        break
                    }
                    if try tabElem.text() == "Upcoming" {
                        await MainActor.run {
                            stage = .upcoming
                        }
                        continue
                    }
                    if try tabElem.text() == "Current" {
                        let currentMeetsCount = await countCurrentMeets(html: html)
                        await MainActor.run {
                            totalMeetsParsedCount += currentMeetsCount ?? 0
                            stage = .past
                        }
                        continue
                    }
                    if try tabElem.text() == "Past Results & Photos" {
                        await MainActor.run {
                            stage = .past
                        }
                        continue
                    }
                    if stage == .upcoming {
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        guard let url = URL(string: link) else { return }
                        await fetchLinkText(url: url)
                        await MainActor.run {
                            // Parses subpage and gets meet names and links
                            if let text = linkText,
                               let result = countMeetNames(text: text) {
                                totalMeetsParsedCount += result
                            }
                        }
                    } else if try stage == .past && tabElem.attr("href") == "#" {
                        try await MainActor.run {
                            pastYear = try tabElem.text()
                        }
                    }
                    else if stage == .past {
                        // Gets a set of all past years currently in the database
                        if let storedMeets = storedMeets, storedPastMeetYears == nil {
                            pullStoredPastMeetYears(storedMeets: storedMeets)
                        }
                        
                        // Skip years that are earlier than current year and already in the database
                        if let past = Int(pastYear),
                            let current = Int(currentYear),
                            past < current,
                            let storedPastMeetYears = storedPastMeetYears,
                            storedPastMeetYears.contains(past) {
                            continue
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        guard let url = URL(string: link) else { return }
                        await fetchLinkText(url: url)
                        
                        // Counts subpage and gets number of meet names
                        await MainActor.run {
                            if let text = linkText,
                               let result = countMeetNames(text: text) {
                                totalMeetsParsedCount += result
                            }
                        }
                    }
                }
            } catch {
                print("Error counting meets")
            }
            await MainActor.run {
                stage = nil
            }
        }
    
    // Parses only upcoming and current meets and skips counting (should not be run on the
    // environment object MeetParser; this is currently used on the Home page to speed up loading)
    func parsePresentMeets() async throws {
        do {
            // Initialize meet parse from index page
            guard let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php") else { return }
            
            // This sets getTextModel's text field equal to the HTML from url
            await getTextModel.fetchText(url: url)
            
            if let html = getTextModel.text {
                let document: Document = try SwiftSoup.parse(html)
                guard let body = document.body() else {
                    return
                }
                let menu = try body.getElementById("dm_menu_centered")
                guard let menuTabs = try menu?.getElementsByTag("ul")[0].getElementsByTag("li") else { return }
                for tab in menuTabs {
                    // tabElem is one of the links from the tabs in the menu bar
                    let tabElem = try tab.getElementsByAttribute("href")[0]
                    
                    if try tabElem.text() == "Past Results & Photos" {
                        // Assigns currentMeets to empty list in case without current tab
                        if currentMeets == nil {
                            await MainActor.run {
                                currentMeets = []
                            }
                        }
                        break
                    }
                    if try tabElem.text() == "Upcoming" {
                        await MainActor.run {
                            stage = .upcoming
                        }
                        continue
                    }
                    if try tabElem.text() == "Current" {
                        await parseCurrentMeets(html: html)
                        break
                    }
                    if stage == .upcoming {
                        if upcomingMeets == nil {
                            await MainActor.run {
                                upcomingMeets = [:]
                            }
                        }
                        if upcomingMeets![currentYear] == nil {
                            await MainActor.run {
                                upcomingMeets![currentYear] = [:]
                            }
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        guard let url = URL(string: link) else { return }
                        await fetchLinkText(url: url)
                        try await MainActor.run {
                            // Parses subpage and gets meet names and links
                            if let text = linkText,
                               let result = getMeetInfo(text: text) {
                                try upcomingMeets![currentYear]![tabElem.text()] = result
                            }
                        }
                    }
                }
            }
        } catch {
            print("Parse present meets failed")
        }
    }
    
    // Parses the "Meets" tab from the homepage and stores results in MeetDict and CurrentMeetDict
    // objects to the respective fields in MeetParser
    func parseMeets(storedMeets: FetchedResults<DivingMeet>? = nil, skipCount: Bool = false) async throws {
        do {
            // Initialize meet parse from index page
            guard let url = URL(string: "https://secure.meetcontrol.com/divemeets/system/index.php") else { return }
            
            // This sets getTextModel's text field equal to the HTML from url
            await getTextModel.fetchText(url: url)
            
            if let html = getTextModel.text {
                if !skipCount {
                    try await countParsedMeets(html: html, storedMeets: storedMeets)
                }
                await MainActor.run {
                    if skipCount {
                        totalMeetsParsedCount = 10000
                    }
                    isFinishedCounting = true
                }
                
                let document: Document = try SwiftSoup.parse(html)
                guard let body = document.body() else {
                    return
                }
                let menu = try body.getElementById("dm_menu_centered")
                guard let menuTabs = try menu?.getElementsByTag("ul")[0].getElementsByTag("li") else { return }
                for tab in menuTabs {
                    // tabElem is one of the links from the tabs in the menu bar
                    let tabElem = try tab.getElementsByAttribute("href")[0]
                    if try tabElem.text() == "Find" {
                        break
                    }
                    if try tabElem.text() == "Upcoming" {
                        await MainActor.run {
                            stage = .upcoming
                        }
                        continue
                    }
                    if try tabElem.text() == "Current" {
                        await parseCurrentMeets(html: html)
                        await MainActor.run {
                            meetsParsedCount += (currentMeets ?? []).count
                            stage = .past
                        }
                        continue
                    }
                    if try tabElem.text() == "Past Results & Photos" {
                        await MainActor.run {
                            // Assigns currentMeets to empty list if we don't see the tab in menu,
                            // sets that we have checked and there aren't any current meets
                            if currentMeets == nil {
                                currentMeets = []
                            }
                            
                            stage = .past
                        }
                        continue
                    }
                    
                    if stage == .upcoming {
                        if upcomingMeets == nil {
                            await MainActor.run {
                                upcomingMeets = [:]
                            }
                        }
                        if upcomingMeets![currentYear] == nil {
                            await MainActor.run {
                                upcomingMeets![currentYear] = [:]
                            }
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        guard let url = URL(string: link) else { return }
                        await fetchLinkText(url: url)
                        try await MainActor.run {
                            // Parses subpage and gets meet names and links
                            if let text = linkText,
                               let result = getMeetInfo(text: text) {
                                try upcomingMeets![currentYear]![tabElem.text()] = result
                                meetsParsedCount += result.count
                            }
                        }
                    }
                    else if try stage == .past && tabElem.attr("href") == "#" {
                        try await MainActor.run {
                            pastYear = try tabElem.text()
                        }
                    }
                    else if stage == .past {
                        if pastMeets == nil {
                            await MainActor.run {
                                pastMeets = [:]
                            }
                        }
                        if pastMeets![pastYear] == nil {
                            await MainActor.run {
                                pastMeets![pastYear] = [:]
                            }
                        }
                        
                        // Gets a set of all past years currently in the database
                        if let storedMeets = storedMeets, storedPastMeetYears == nil {
                            pullStoredPastMeetYears(storedMeets: storedMeets)
                        }
                        
                        // Skip years that are earlier than current year and already in the database
                        if let past = Int(pastYear),
                           let current = Int(currentYear),
                           past < current,
                           let storedPastMeetYears = storedPastMeetYears,
                           storedPastMeetYears.contains(past) {
                            continue
                        }
                        
                        // tabElem.attr("href") is an organization link here
                        let link = try tabElem.attr("href")
                            .replacingOccurrences(of: " ", with: "%20")
                            .replacingOccurrences(of: "\t", with: "")
                        
                        // Gets HTML from subpage link and sets linkText to HTML;
                        // This pulls the html for an org's page
                        guard let url = URL(string: link) else { return }
                        await fetchLinkText(url: url)
                        
                        // Parses subpage and gets meet names and links
                        try await MainActor.run {
                            // Assigns year and org to dict of meet names and
                            // links to results page
                            if let text = linkText,
                               let result = getMeetInfo(text: text) {
                                try pastMeets![pastYear]![tabElem.text()] = result
                                meetsParsedCount += result.count
                            }
                        }
                    }
                }
            } else {
                print("Could not fetch html")
            }
        } catch {
            print("Error parsing meets")
        }
    }
    
    func printPastMeets() {
        if let pastMeets = pastMeets {
            let keys = Array(pastMeets.keys)
            let left = keys[0 ..< keys.count / 2]
            let right = keys[keys.count / 2 ..< keys.count]
            
            print("[")
            for k in left {
                print("\(k): \(pastMeets[k]!),")
            }
            for k in right {
                print("\(k): \(pastMeets[k]!),")
            }
            print("]")
        } else {
            print([String:String]())
        }
    }
}

struct MeetParserView: View {
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
    @FetchRequest(sortDescriptors: []) var meets: FetchedResults<DivingMeet>
    @State var finishedParsing: Bool = false
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button("Upcoming") {
                    print(p.upcomingMeets ?? [:])
                }
                Spacer()
                Button("Current") {
                    print(p.currentMeets ?? [])
                }
                Spacer()
                Button("Past") {
                    p.printPastMeets()
                }
                Spacer()
            }
            Spacer()
            
            if !finishedParsing {
                ProgressView()
            } else {
                Button("Print Past Meet Results") {
                    if let pastMeets = p.pastMeets {
                        let meetName = "Phoenix Fall Classic @ UChicago"
                        let choice = pastMeets["2022"]![
                            "National Collegiate Athletic Association (NCAA)"]![0].1
                        Task {
                            let result = await p.parsePastMeetResults(meetName: meetName,
                                                                      link: choice)
                            print(result!)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            Task {
                finishedParsing = false
                
                // This sets p's upcoming, current, and past meets fields
                try await p.parseMeets(storedMeets: meets)
                
                finishedParsing = true
                print("Finished parsing")
            }
        }
    }
    
}
