//
//  CollegeLogoParser.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/3/23.
//

import Foundation
import SwiftSoup

private func getLastPageIdx(_ link: String) async -> Int? {
    do {
        let textLoader = GetTextAsyncModel()
        guard let url = URL(string: link) else { return nil }
        await textLoader.fetchText(url: url)
        
        guard let html = textLoader.text else { return nil }
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let pager = try body.getElementsByClass("school-pager")
        if pager.count == 0 { return nil }
        
        let anchors = try pager[0].getElementsByTag("a")
        guard let lastLink = anchors.last() else { return nil }
        let linkSplit = try lastLink.attr("href").split(separator: "/")
        
        guard let last = linkSplit.last, let num = Int(last) else { return nil }
        
        return num
    } catch {
        print("Failed to get last page index")
    }
    
    return nil
}

// Parses college logo images and stores them as name-link key-value pairs
func parseCollegeLogos() async -> [String: String]? {
    let textLoader = GetTextAsyncModel()
    let link = "https://www.ncaa.com/schools-index/"
    var result: [String: String] = [:]
    
    guard let lastPageIdx: Int = await getLastPageIdx(link) else { return nil }
    
    do {
        for page in 0..<lastPageIdx+1 {
            let parseLink: String = link + String(page)
            
            guard let url = URL(string: parseLink) else { return nil }
            await textLoader.fetchText(url: url)
            guard let html = textLoader.text else { return nil }
            
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return nil }
            let rows = try body.getElementsByTag("tr")
            
            for row in rows {
                let tds = try row.getElementsByTag("td")
                if tds.count != 3 { continue }
                
                let imgs = try tds[0].getElementsByTag("img")
                if imgs.count == 0 { continue }
                let img = imgs[0]
                let link = try img.attr("data-src")
                
                let name = String(try tds[2].text())
                
                result[name] = link
            }
        }
        
        return result
    } catch {
        print("Failed to parse college logos")
    }
    
    return nil
}

func saveCollegesToDevice() async throws {
    let folderUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let fileURL = folderUrls[0].appendingPathComponent("collegeLogos.json")
    
    guard let result = await parseCollegeLogos() else { return }
    let writeData = try JSONSerialization.data(withJSONObject: result)
    try writeData.write(to: fileURL)
    print(fileURL)
}

private func loadCollegesFromDevice() -> [String: String] {
    do {
        let folderUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = folderUrls[0].appendingPathComponent("collegeLogos.json")
        
        let data = try Data(contentsOf: fileURL)
        return try JSONSerialization.jsonObject(with: data) as! [String: String]
    } catch {
        Task {
            try await saveCollegesToDevice()
        }
        
        return loadCollegesFromDevice()
    }
}

// Convenience function, above functions were used for generation
func getCollegeLogoData() -> [String: String]? {
    if let url = Bundle.main.url(forResource: "collegeLogos", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            return try decoder.decode([String: String].self, from: data)
        } catch {
            print("Error decoding JSON object: \(error)")
        }
    }
    
    return nil
}
