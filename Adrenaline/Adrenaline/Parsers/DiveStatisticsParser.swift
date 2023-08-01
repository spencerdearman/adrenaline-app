//
//  DiveStatisticsParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI
import SwiftSoup

final class DiveStatisticsParser: ObservableObject {
    @Published var diveDict = [String: (String, Double)]()
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [String: (String, Double)] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let tables = try body.getElementsByTag("table")
        let overall = try tables[2].getElementsByTag("tr")
        
        var dive = ""
        var height = ""
        var score = 0.0
        
        for (i, t) in overall.enumerated() {
            if i > 2 {
                let row = try t.getElementsByTag("td")
                dive = try row[0].text()
                height = try row[1].text().replacingOccurrences(of: "M", with: "")
                score = Double(try row[4].text())!
                await MainActor.run { [dive, height, score] in
                    diveDict[dive] = (height, score)
                }
            }
        }
        return diveDict
    }
    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parse(html: html)
                await MainActor.run {
                    diveDict = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("DiveStatisticsParser: Could not fetch text")
        }
    }
}
