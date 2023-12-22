//
//  MeetParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/22/23.
//

import CoreData
import SwiftUI
import SwiftSoup

//                      id  , name   , org    , link   , startDate, endDate, city , state  , country
typealias MeetRecord = (Int?, String?, String?, String?, String?, String?, String?, String?, String?)

//                             [(MeetRecord, resultsLink)]
typealias CurrentMeetRecords = [(MeetRecord, String?)]

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

// Turns MeetDict into [(meetId, name, org, link, startDate, endDate, city, state, country)]
func dictToTuple(_ dict: MeetDict) -> [MeetRecord] {
    var result: [MeetRecord] = []
    for (_, orgDict) in dict {
        for (org, meetDict) in orgDict {
            for (name, link, startDate, endDate, city, state, country) in meetDict {
                if let linkSplit = link.split(separator: "=").last {
                    if let meetId = Int(linkSplit) {
                        result.append(
                            (meetId, name, org, link, startDate, endDate, city, state, country))
                    }
                }
            }
        }
    }
    
    return result
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
    // Meets that have already happened
    private let currentYear = String(Calendar.current.component(.year, from: Date()))
    private var linkText: String?
    private var stage: Stage?
    private let loader = GetTextAsyncLoader()
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    // Gets html text from async loader
    private func fetchLinkText(url: URL) async {
        let text = try? await loader.getText(url: url)
        await MainActor.run {
            self.linkText = text
        }
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
    
    private func waitForNetworkAccess() async throws {
        while blockingNetwork {
            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
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
                                if upcomingMeets != nil && upcomingMeets![currentYear] != nil {
                                    try upcomingMeets![currentYear]![tabElem.text()] = result
                                }
                            }
                        }
                    }
                }
                // Catches case when there is no "Upcoming" tab in the Meets tab
                if upcomingMeets == nil {
                    await MainActor.run {
                        upcomingMeets = [:]
                    }
                }
            }
        } catch {
            print("Parse present meets failed")
        }
    }
}

struct MeetParserView: View {
    @StateObject private var getTextModel = GetTextAsyncModel()
    @StateObject private var p = MeetParser()
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
            }
            
            Spacer()
        }
        .onAppear {
            Task {
                finishedParsing = false
                
                // This sets p's upcoming, current, and past meets fields
                try await p.parsePresentMeets()
                
                finishedParsing = true
                print("Finished parsing")
            }
        }
    }
}
