//
//  EventPageParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import SwiftSoup

final class EventPageHTMLParser: ObservableObject {
    //  Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff. SynchoName SynchroLink
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
                
                // TODO: add synchro data values after testing in live results
                let place = String(i - 4)
                let name = try line[0].text()
                let nameLink = try leadingLink + line[0].getElementsByTag("a").attr("href")
                let team = try line[1].text()
                let teamLink = try leadingLink + line[1].getElementsByTag("a").attr("href")
                let score = try line[3].text()
                let scoreLink = try leadingLink + line[3].getElementsByTag("a").attr("href")
                let scoreDiff = try line[4].text()
                let eventName = try overall[2].text()
                
                let items = [place, name, nameLink, team, teamLink, score, scoreLink, scoreDiff, eventName]
                
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
            print("Could not fetch text")
        }
    }
    
}
