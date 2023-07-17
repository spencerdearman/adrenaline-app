//
//  FinishedLiveResultsParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/10/23.
//

import Foundation
import SwiftSoup

class FinishedLiveResultsParser: ObservableObject {
    @Published var resultsRecords: [[String]] = []
    @Published var eventTitle: String = ""
    
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    func getFinishedLiveResultsRecords(html: String) async {
        resultsRecords = []
        eventTitle = ""
        
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return }
            let content = try body.attr("id", "Results")
            let rows = try content.getElementsByTag("tr")
            
            for (i, row) in rows.array().enumerated() {
                // Breaks out of the loop once it reaches the end of the table with this message
                if try row.text().hasPrefix("Official") {
                    break
                }
                
                if i == 1 {
                    eventTitle = try row.text()
                        .replacingOccurrences(of: "Unofficial Statistics", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else if i > 3 {
                    let text = try row.text()
                    let links = try row.getElementsByTag("a")
                    assert(links.count == 2)
                    print(try links.text())
                    
                    let firstComps = text.split(separator: " ", maxSplits: 1)
                    guard let place = firstComps.first else { return }
                    
                    let comps = String(firstComps.last ?? "").split(separator: " ", maxSplits: 1)
                    guard let score = comps.first else { return }
                    
                    guard let nextComps = comps.last?.split(separator: "(", maxSplits: 1)
                    else { return }
                    guard let name = nextComps.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                    else { return }
                    let nameSplit = name.split(separator: " ")
                    guard let last = nameSplit.last else { return }
                    let first = nameSplit.dropLast().joined(separator: " ")
                    
                    guard let finalComps = nextComps.last?.split(separator: " ") else { return }
                    
                    if finalComps.count < 3 { return }
                    guard var team = finalComps.first else { return }
                    team.removeLast()
                    
                    let eventAvgScore = String(finalComps[1])
                    guard let avgRoundScore = finalComps.last else { return }
                    
                    resultsRecords.append([String(place), first, String(last),
                                           try leadingLink + links[1].attr("href"),
                                           String(team), String(score),
                                           try leadingLink + links[0].attr("href"),
                                           eventAvgScore, String(avgRoundScore)])
                }
            }
        } catch {
            print("Failed to parse finished live event")
        }
    }
}
