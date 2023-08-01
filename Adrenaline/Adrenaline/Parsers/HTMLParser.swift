//
//  HTMLParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 3/14/23.
//

import SwiftUI
import SwiftSoup

typealias DiverProfileRecords = [String: [String]]

final class HTMLParser: ObservableObject {
    @Published var myData = [[String]]()
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [[String]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return [[]] }
//        let test = try body.getElementsByTag("body")
//        print(body == test[0])
//        let main = try body.getElementsByTag("body").compactMap({try? $0.html()})
//        let html = main[0]
//        let html = try body.html()
//        let doc: Document = try SwiftSoup.parse(html)
        
        var myData = [[String]]()
        let myRows = try body.getElementsByTag("tr")
//        for row in myRows {
//        try myRows?.forEach({ row in
            let tempString = try myRows[0].text()
            let split = tempString.components(separatedBy: "  ")
            myData.append(split)
//            break
//        }
        
        return myData
    }
    
    func parseReturnString(html: String) -> String? {
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return nil
            }
            let main = try body.getElementsByTag("body").compactMap({try? $0.html()})
            return main.first
        }
        catch {
            print("Error Parsing: " + String(describing: error))
            return nil
        }
    }
    
    func testingParser(urlString: String) -> String? {
        guard let url = URL(string: urlString) else {
            return ""
        }
        do {
            let html = try String(contentsOf: url)
            let stringData = parseReturnString(html: html)
            return stringData
        } catch {
            print("Error fetching HTML: \(error)")
        }
        return ""
    }
    
    func parse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parse(html: html)
                await MainActor.run {
                    myData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("HTMLParser: Could not fetch text")
        }
    }
    
    
//    func getRecords(_ html: String) -> DiverProfileRecords {
//        let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
//        var result: DiverProfileRecords = [:]
//        do {
//            let document: Document = try SwiftSoup.parse(html)
//            guard let body = document.body() else {
//                return [:]
//            }
//            let content = try body.getElementById("dm_content")
//            let links = try content?.getElementsByClass("showresults").select("a")
//            try links?.forEach({ l in
//                // Adds an empty list value to a new key
//                if !result.keys.contains(try l.text()) {
//                    result[try l.text()] = []
//                }
//                result[try l.text()]!.append(try leadingLink + l.attr("href"))
//            })
//        }
//        catch {
//            print("Parsing records failed")
//        }
//        return result
//    }
}
