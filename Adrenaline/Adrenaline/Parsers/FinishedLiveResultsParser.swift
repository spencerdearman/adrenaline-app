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
                    var result: [String] = []
                    let text = try row.text()
                    let links = try row.getElementsByTag("a")
                    
                    let firstComps = text.split(separator: " ", maxSplits: 1)
                    guard let place = firstComps.first else { return }
                    result.append(String(place))
                    
                    let comps = String(firstComps.last ?? "").split(separator: " ", maxSplits: 1)
                    guard let score = comps.first else { return }
                    
                    var eventAvgScore: String = ""
                    var avgRoundScore: String = ""
                    
                    guard let partnersComps = comps.last?.split(separator: " / ", maxSplits: 1)
                    else { return }
                    
                    for (i, diver) in partnersComps.enumerated() {
                        // Removes potential starting (A) or (B) from name
                        var diverComps: [String.SubSequence] = []
                        if diver.filter({ $0 == ")" }).count > 1 {
                            diverComps = diver.split(separator: ") ", maxSplits: 1)
                        } else {
                            diverComps = [diver]
                        }
                        
                        guard let nextComps = diverComps.last?
                            .split(separator: "(", maxSplits: 1) else { return }
                        
                        guard let name = nextComps.first?
                            .trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                        let nameSplit = name.split(separator: " ")
                        guard let last = nameSplit.last else { return }
                        let first = nameSplit.dropLast().joined(separator: " ")
                        
                        guard let finalComps = nextComps.last?
                            .split(separator: " ") else { return }
                        
                        if finalComps.count == 0 { return }
                        else if finalComps.count == 3 {
                            eventAvgScore = String(finalComps[1])
                            guard let last = finalComps.last else { return }
                            avgRoundScore = String(last)
                        }
                        
                        guard var team = finalComps.first else { return }
                        team.removeLast()
                        
                        result += [first, String(last),
                                   try leadingLink + links[i + 1].attr("href"),
                                   String(team)]
                        
                        if i == 0 {
                            result += [String(score), try leadingLink + links[0].attr("href")]
                        }
                        if i == partnersComps.count - 1 {
                            result.insert(eventAvgScore, at: 7)
                            result.insert(avgRoundScore, at: 8)
                        }
                    }
                    
                    resultsRecords.append(result)
                }
            }
        } catch {
            print("Failed to parse finished live event")
        }
    }
}
