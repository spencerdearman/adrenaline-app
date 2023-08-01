//
//  EventPageParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import SwiftSoup

final class EventPageHTMLParser: ObservableObject {
    //  Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff. SynchroName SynchroNameLink SynchroTeam SynchroTeamLink
    @Published var eventPageData = [[String]]()
    @Published var parsingPageData = [[String]]()
    
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink = "https://secure.meetcontrol.com/divemeets/system/"
    
    func parseEventPage(html: String) async throws -> [[String]]{
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return []
        }
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        for (i, t) in overall.enumerated(){
            if 5 <= i && i < overall.count - 1 {
                let line = try t.getElementsByTag("td")
                
                let place = String(i - 4)
                let nameSplit = try line[0].text().split(separator: " / ", maxSplits: 1)
                if nameSplit.count == 0 { return [[]] }
                let name = String(nameSplit[0])
                let linkSplit = try line[0].getElementsByTag("a").map { try $0.attr("href") }
                if linkSplit.count == 0 { return [[]] }
                let nameLink = String(leadingLink + linkSplit[0])
                let teamSplit = try line[1].text().split(separator: " / ", maxSplits: 1)
                if teamSplit.count == 0 { return [[]] }
                let team = String(teamSplit[0])
                let teamLinkSplit = try line[1].getElementsByTag("a").map { try $0.attr("href") }
                if teamLinkSplit.count == 0 { return [[]] }
                let teamLink = String(leadingLink + teamLinkSplit[0])
                let score = try line[3].text()
                let scoreLink = try leadingLink + line[3].getElementsByTag("a").attr("href")
                let scoreDiff = try line[4].text()
                
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
                print(items)
                await MainActor.run { [items] in
                    parsingPageData.append(items)
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
