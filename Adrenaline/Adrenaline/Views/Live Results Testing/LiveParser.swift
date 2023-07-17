//
//  LiveParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/4/23.
//

import SwiftUI
import SwiftSoup

final class LiveParser: ObservableObject {
    @Published var liveData = [String]()
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [String] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return []
        }
        let main = try body.getElementsByTag("tbody")
        //let scores = try main[0].getElementsByTag("tr")
        let scores = try main.select("td[style*=color:000000]")
        var value = 0.0
        return ["Hello"]
    }
    
    func parseWithDelay(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let tableData = try await parse(html: html)
                await MainActor.run {
                    liveData = tableData
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("Could not fetch text")
        }
    }
}




