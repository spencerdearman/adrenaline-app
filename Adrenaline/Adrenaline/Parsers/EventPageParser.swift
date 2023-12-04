//
//  EventPageParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import SwiftSoup

final class EventPageHTMLParser: ObservableObject {
    //  Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff. SynchroName SynchroNameLink
    //  SynchroTeam SynchroTeamLink
    @Published var eventPageData = [[String]]()
    @Published var parsingPageData = [[String]]()
    
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink = "https://secure.meetcontrol.com/divemeets/system/"
    
    func parseEventPage(html: String) async throws -> [[String]]{
        let document: Document = try SwiftSoup.parse(html)
        var disqualifiedDivers: [[String]] = []
        
        guard let body = document.body() else {
            return []
        }
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        for (i, t) in overall.enumerated() {
            if 5 <= i && i < overall.count - 1 {
                let line = try t.getElementsByTag("td")
                
                // Assume not disqualified, handle differently if we discover they are disqualified'
                // during parsing
                var isDisqualified = false
                
                let nameSplit = try line[0].text().split(separator: " / ", maxSplits: 1)
                if nameSplit.count == 0 { return [[]] }
                var name = String(nameSplit[0])
                
                // Check if the diver has scratched and reformat name string
                let checkScratched = name.split(separator: " - - ")
                if checkScratched.count > 1 {
                    name = checkScratched[0] + " (Scratched)"
                }
                
                let linkSplit = try line[0].getElementsByTag("a").map { try $0.attr("href") }
                if linkSplit.count == 0 { return [[]] }
                let nameLink = String(leadingLink + linkSplit[0])
                let teamSplit = try line[1].text().split(separator: " / ", maxSplits: 1)
                if teamSplit.count == 0 { return [[]] }
                let team = String(teamSplit[0])
                let teamLinkSplit = try line[1].getElementsByTag("a").map { try $0.attr("href") }
                if teamLinkSplit.count == 0 { return [[]] }
                let teamLink = String(leadingLink + teamLinkSplit[0])
                
                let place = try line[2].text()
                
                // Disqualified divers are given place 0 (at least when there's only one, they are 
                // given place 0. I am assuming that multiple disqualifications would all get
                // place 0.)
                if let placeInt = Int(place), placeInt < 1 {
                    isDisqualified = true
                }
                
                // Total score, or "Disqualified" if disqualified
                let score = try line[3].text()
                
                // Set values for scoreLink and scoreDiff for disqualified divers instead of
                // parsing
                let scoreLink: String
                let scoreDiff: String
                if isDisqualified {
                    scoreLink = ""
                    scoreDiff = "N/A"
                } else {
                    scoreLink = try leadingLink + line[3].getElementsByTag("a").attr("href")
                    scoreDiff = try line[4].text()
                }
                
                var synchroName: String?
                var synchroLink: String?
                var synchroTeam: String?
                var synchroTeamLink: String?
                if nameSplit.count > 1, linkSplit.count > 1, teamSplit.count > 1,
                   teamLinkSplit.count > 1 {
                    synchroName = String(nameSplit[1])
                    synchroLink = leadingLink + String(linkSplit[1])
                    synchroTeam = String(teamSplit[1])
                    synchroTeamLink = leadingLink + String(teamLinkSplit[1])
                }
                let eventName = try overall[2].text()
                
                var items = [place, name, nameLink, team, teamLink, score, scoreLink, scoreDiff,
                             eventName]
                if let name = synchroName, let link = synchroLink, let team = synchroTeam,
                   let teamLink = synchroTeamLink {
                    items += [name, link, team, teamLink]
                }
                
                // Instead of appending to parsingPageData, append disqualified divers to separate
                // list and add them at the end once we know the last place value
                if isDisqualified {
                    disqualifiedDivers.append(items)
                } else {
                    await MainActor.run { [items] in
                        parsingPageData.append(items)
                    }
                }
            }
        }
        
        // If there were disqualified divers, add them at the end after the last placed diver and
        // give them all the next place number
        if !disqualifiedDivers.isEmpty {
            if let lastRow = parsingPageData.last, let place = Int(lastRow[0]) {
                let newPlace = String(place + 1)
                
                await MainActor.run { [disqualifiedDivers] in
                    parsingPageData += disqualifiedDivers.map {
                        var newRow = $0
                        newRow[0] = newPlace
                        return newRow
                    }
                }
            }
        }
        
        return parsingPageData
    }
    
    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parseEventPage(html: html)
                await MainActor.run {
                    eventPageData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("EventPageHTMLParser: Could not fetch text")
        }
    }
    
}
