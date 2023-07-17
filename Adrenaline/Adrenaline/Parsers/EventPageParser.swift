//
//  EventPageParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import SwiftSoup

final class EventPageHTMLParser: ObservableObject {
    //                             Place  Name   NameLink  Team  TeamLink Score ScoreLink Score Diff.
    @Published var eventPageData = [[String]]()
    @Published var parsingPageData = [[String]]()
    
    let getTextModel = GetTextAsyncModel()
    
    func parseEventPage(html: String) async throws -> [[String]]{
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return []
        }
        
        let beginning = "https://secure.meetcontrol.com/divemeets/system/"
        var partNameLink = ""
        var partTeamLink = ""
        var partScoreLink = ""
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        for (i, t) in overall.enumerated(){
            if 5 <= i && i < overall.count - 1 {
                var tempList: [String] = []
                let line = try t.getElementsByTag("td")
                tempList.append(String(i - 4))
                tempList.append(try line[0].text())
                partNameLink = try line[0].getElementsByTag("a").attr("href")
                tempList.append(beginning + partNameLink)
                tempList.append(try line[1].text())
                partTeamLink = try line[1].getElementsByTag("a").attr("href")
                tempList.append(beginning + partTeamLink)
                tempList.append(try line[3].text())
                partScoreLink = try line[3].getElementsByTag("a").attr("href")
                tempList.append(beginning + partScoreLink)
                tempList.append(try line[4].text())
                tempList.append(try overall[2].text())
                
                await MainActor.run { [tempList] in
                    parsingPageData.append(tempList)
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
