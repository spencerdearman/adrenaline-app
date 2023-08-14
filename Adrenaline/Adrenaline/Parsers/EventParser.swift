//
//  EventParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI
import SwiftSoup

final class EventHTMLParser: ObservableObject {
    @Published var myData = [Int:[String:[String:(String, Double, String, String)]]]()
    @Published var diveTableData = [Int: (String, String, String, Double, Double, Double, String)]()
    @Published var eventData: (String, String, String, Double, Double, Double, String) =
    ("","", "", 0.0, 0.0, 0.0, "")
    @Published var eventDictionary = [String:(String, Double, String, String)]()
    @Published var innerDictionary = [String:[String:(String, Double, String, String)]]()
    @Published var mainDictionary = [Int:[String:[String:(String, Double, String, String)]]]()
    @Published var meetScores = [Int: (String, String, String, Double, Double, Double, String)]()
    
    // Keeps track of main meet links for each event parsed, relays back to global for each diverID
    @Published var cachedMainMeetLinks: [String: String] = [:]
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [Int:[String:[String:(String, Double, String, String)]]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let main = try body.getElementsByTag("table")
        
        //Getting the overarching td and then pulling the 3 items within
        var hasUpcomingMeets = false
        if main.count < 2 { return [:] }
        var overall = try main[1].getElementsByTag("tr")
        var string = [String]()
        var eventLinkAppend = ""
        var counter = 0
        var meetEvent = ""
        var eventPlace = ""
        var eventScore = 0.0
        var eventLink = ""
        var meetName = ""
        var meetLink = ""
      
        for (_, t) in overall.enumerated() {
            let tester = try t.getElementsByTag("td")
            if try tester.count >= 3 && tester[2].text().contains("Dive Sheet") {
                hasUpcomingMeets = true
            }
        }
        if hasUpcomingMeets {
            if main.count < 3 { return [:] }
            overall = try main[2].getElementsByTag("tr")
        }
        
        for (i, t) in overall.enumerated() {
            let testString = try t.text()
            if i == 0 {
                continue
            } else if try testString.contains(".") && t.getElementsByTag("td").count > 2 {
                meetEvent = try t.getElementsByTag("td")[0].text()
                    .replacingOccurrences(of: "  ", with: "")
                eventPlace = try t.getElementsByTag("td")[1].text()
                    .replacingOccurrences(of: " ", with: "")
                eventScore = Double(try t.getElementsByTag("td")[2].text())!
                eventLinkAppend = try t.getElementsByTag("a").attr("href")
                eventLink = "https://secure.meetcontrol.com/divemeets/system/" + eventLinkAppend
                string.append(try t.text())
                
                if !cachedMainMeetLinks.keys.contains(meetName) {
                    meetLink = (eventLink.components(separatedBy: "&").first ?? "")
                        .replacingOccurrences(of: "divesheet", with: "meet")

                    await MainActor.run { [meetName, meetLink] in
                        cachedMainMeetLinks[meetName] = meetLink
                    }
                } else {
                    meetLink = cachedMainMeetLinks[meetName] ?? ""
                }
                
                await MainActor.run { [meetEvent, eventPlace, eventScore, eventLink, meetLink] in
                    eventDictionary[meetEvent] = (eventPlace, eventScore, eventLink, meetLink)
                }
            } else if counter != 0 {
                await MainActor.run { [meetName, counter] in
                    innerDictionary[meetName] = eventDictionary
                    mainDictionary[counter] = innerDictionary
                    innerDictionary = [:]
                    eventDictionary = [:]
                }
                meetName = try t.text()
                counter += 1
            } else {
                meetName = try t.text()
                counter += 1
            }
        }
        
        if counter == 1 {
            await MainActor.run { [meetName, counter] in
                innerDictionary[meetName] = eventDictionary
                mainDictionary[counter] = innerDictionary
                innerDictionary = [:]
                eventDictionary = [:]
            }
        }
        return mainDictionary
    }
    
    
    
    func parseEvent(html: String) async throws ->
    (String, String, String, Double, Double, Double, String) {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return ("", "", "", 0.0, 0.0, 0.0, "")
        }
        
        var meetPageLink = ""
        var meetDates = ""
        var organization = ""
        var totalNetScore = 0.0
        var totalDD  = 0.0
        var totalScore = 0.0
        var eventPageLink = ""
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        let finalRow = try overall[overall.count - 2].getElementsByTag("td")
        //Getting the link to the meet page, not to be confused with the meetLink --Working
        
        let temp = try overall[3].getElementsByTag("strong").text()
        guard let range = temp.range(of: " - ") else { throw NSError() }
        organization = String(temp.suffix(from: range.upperBound))
        
        meetPageLink = "https://secure.meetcontrol.com/divemeets/system/" +
        (try overall[0].getElementsByTag("a").attr("href"))
        
        eventPageLink = "https://secure.meetcontrol.com/divemeets/system/" +
        (try overall[2].getElementsByTag("a").attr("href"))
        
        meetDates = try overall[1].getElementsByTag("Strong").text()
        totalNetScore = Double(try finalRow[2].text()) ?? 0.0
        totalDD = Double(try finalRow[3].text()) ?? 0.0
        totalScore = Double(try finalRow[4].text()) ?? 0.0
        return (meetPageLink, meetDates, organization, totalNetScore, totalDD, totalScore, eventPageLink)
    }
    
    
    func parseDiveTable(html: String) async throws ->
    [Int: (String, String, String, Double, Double, Double, String)] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        var order = 0
        var diveNum = ""
        var height = ""
        var name = ""
        var netScore = 0.0
        var DD = 0.0
        var score = 0.0
        var scoreLink = ""
        
        let table = try body.getElementsByTag("table")
        let diveTable = try table[0].getElementsByAttribute("bgcolor")
        for dive in diveTable {
            let diveInformation = try dive.getElementsByTag("td")
            order = Int(try diveInformation[0].text()) ?? 0
            
            let tempNum = try diveInformation[1].html().split(separator:"<br>")
            if tempNum.count > 1{
                diveNum = tempNum[1] + " (Changed from " + tempNum[0] + ")"
            } else {
                diveNum = try diveInformation[1].text()
            }
            height = try String(diveInformation[2].html().split(separator:"<br>").last!)
            name = try String(diveInformation[3].html().split(separator:"<br>").last!)
            let tempScore = (try diveInformation[4].text())
                .replacingOccurrences(of: " Failed Dive", with: "")
            let updatedScore = (tempScore.replacingOccurrences(of: "Dive Changed", with: ""))
            netScore = Double(updatedScore) ?? 0.0
            
            if try diveInformation[5].text().count > 4 {
                DD = Double(try diveInformation[5].text().suffix(4)) ?? 0.0
            } else {
                DD = Double(try diveInformation[5].text()) ?? 0.0
            }
            score = Double(try diveInformation[6].text()
                .replacingOccurrences(of: "  ", with: "")) ?? 0.0
            scoreLink = "https://secure.meetcontrol.com/divemeets/system/" +
            (try diveInformation[6].getElementsByTag("a").attr("href"))
            await MainActor.run { [order, diveNum, height, name, netScore, DD, score, scoreLink] in
                meetScores[order] = (diveNum, height, name, netScore, DD, score, scoreLink)
            }
        }
        return meetScores
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
            print("EventHTMLParser: Could not fetch text")
        }
    }
    
    func eventParse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let data = try await parseEvent(html: html)
                await MainActor.run {
                    eventData = data
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("EventHTMLParser: Could not fetch event text")
        }
    }
    
    func tableDataParse(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // This sets getTextModel's text field equal to the HTML from url
        await getTextModel.fetchText(url: url)
        
        if let html = getTextModel.text {
            do {
                let tableData = try await parseDiveTable(html: html)
                await MainActor.run {
                    diveTableData = tableData
                }
            } catch {
                print("Error parsing HTML: \(error)")
            }
        } else {
            print("EventHTMLParser: Could not fetch table text")
        }
    }
}
