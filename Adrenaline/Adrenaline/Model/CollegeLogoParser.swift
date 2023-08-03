//
//  CollegeLogoParser.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/3/23.
//

import Foundation
import SwiftSoup

// Parses college logo images and stores them as name-link key-value pairs
func parseCollegeLogos() async -> [String: String]? {
    let textLoader = GetTextAsyncModel()
    let link = "https://1000logos.net/american-colleges-ncaa/"
    var result: [String: String] = [:]
    
    do {
        for page in 1..<5 {
            var parseLink: String = link
            if page > 1 {
                parseLink += "/page/\(page)"
            }
            
            guard let url = URL(string: parseLink) else { return nil }
            await textLoader.fetchText(url: url)
            guard let html = textLoader.text else { return nil }
            
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return nil }
            let divs = try body.getElementsByClass("small-post-img")
            
            for div in divs {
                let imgs = try div.getElementsByTag("img")
                if imgs.count == 0 { continue }
                
                let img = imgs[0]
                
                let name = String(try img.attr("alt").dropLast(5))
                let link = try img.attr("data-src")
                
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
}

func loadCollegesFromDevice() -> [String: String] {
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
