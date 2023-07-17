//
//  ScoringParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/18/23.
//

import SwiftUI
import SwiftSoup

final class ScoreHTMLParser: ObservableObject {
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> String {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return ""
        }
        let main = try body.getElementsByTag("tbody")
        //let scores = try main[0].getElementsByTag("tr")
        let scores = try main.select("td[style*=color:000000]")
        let scoreList = try scores.text().components(separatedBy: " ").compactMap { Double($0) }
        let formatted = "| " + scoreList.map { String($0) }.joined(separator: " | ") + " |"
        return formatted
    }
    
    func parse(urlString: String) async -> String {
        guard let url = URL(string: urlString) else { return "" }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                return try await parse(html: html)
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
        return ""
    }
}
