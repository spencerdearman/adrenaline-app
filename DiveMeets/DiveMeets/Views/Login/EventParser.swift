//
//  EventParser.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI
import SwiftSoup

final class EventHTMLParser: ObservableObject {
    @Published var myData = [Int:[String:[String:(String, Double, String)]]]()
    @Published var diveTableData = [Int: (String, String, String, Double, Double, Double, String)]()
    @Published var eventData: (String, String, String, Double, Double, Double) = ("","", "", 0.0, 0.0, 0.0)
    @Published var eventDictionary = [String:(String, Double, String)]()
    @Published var innerDictionary = [String:[String:(String, Double, String)]]()
    @Published var mainDictionary = [Int:[String:[String:(String, Double, String)]]]()
    @Published var meetScores = [Int: (String, String, String, Double, Double, Double, String)]()
    
    let getTextModel = GetTextAsyncModel()
    
    func parse(html: String) async throws -> [Int:[String:[String:(String, Double, String)]]] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        let main = try body.getElementsByTag("table")
        
        //Getting the overarching td and then pulling the 3 items within
        let overall = try main[1].getElementsByTag("tr")
        var string = [String]()
        var eventLinkAppend = ""
        var counter = 0
        var meetEvent = ""
        var eventPlace = ""
        var eventScore = 0.0
        var eventLink = ""
        var meetName = ""
        for (i, t) in overall.enumerated(){
            let testString = try t.text()
            if i == 0 {
                continue
            } else if testString.contains(".") {
                meetEvent = try t.getElementsByTag("td")[0].text().replacingOccurrences(of: "  ", with: "")
                eventPlace = try t.getElementsByTag("td")[1].text().replacingOccurrences(of: " ", with: "")
                eventScore = Double(try t.getElementsByTag("td")[2].text())!
                eventLinkAppend = try t.getElementsByTag("a").attr("href")
                eventLink = "https://secure.meetcontrol.com/divemeets/system/" + eventLinkAppend
                string.append(try t.text())
                eventDictionary[meetEvent] = (eventPlace, eventScore, eventLink)
            } else if counter != 0 {
                innerDictionary[meetName] = eventDictionary
                mainDictionary[counter] = innerDictionary
                meetName = try t.text()
                innerDictionary = [:]
                eventDictionary = [:]
                counter += 1
            } else {
                meetName = try t.text()
                counter += 1
            }
        }
        return mainDictionary
    }
    
    func parseEvent(html: String) async throws -> (String, String, String, Double, Double, Double) {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return ("", "", "", 0.0, 0.0, 0.0)
        }
        
        var meetPageLink = ""
        var meetDates = ""
        var organization = ""
        var totalNetScore = 0.0
        var totalDD  = 0.0
        var totalScore = 0.0
        
        let table = try body.getElementsByTag("table")
        let overall = try table[0].getElementsByTag("tr")
        let finalRow = try overall[overall.count - 2].getElementsByTag("td")
        //Getting the link to the meet page, not to be confused with the meetLink --Working
        
        let temp = try overall[3].getElementsByTag("strong").text()
        let range = temp.range(of: " - ")
        organization = String(temp.suffix(from: range!.upperBound))
        
        meetPageLink = "https://secure.meetcontrol.com/divemeets/system/" + (try overall[0].getElementsByTag("a").attr("href"))
        meetDates = try overall[1].getElementsByTag("Strong").text()
        totalNetScore = Double(try finalRow[2].text())!
        totalDD = Double(try finalRow[3].text())!
        totalScore = Double(try finalRow[4].text())!
        return (meetPageLink, meetDates, organization, totalNetScore, totalDD, totalScore)
    }
    
    
    func parseDiveTable(html: String) async throws -> [Int: (String, String, String, Double, Double, Double, String)] {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else {
            return [:]
        }
        
        //Variable Hell
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
            for (i, cell) in diveInformation.enumerated() {
                if i == 0 {
                    order = Int(try cell.text())!
                } else if i == 1 {
                    diveNum = try cell.text()
                } else if i == 2 {
                    height = try cell.text()
                } else if i == 3 {
                    name = try String(cell.html().split(separator:"<br>").last!)
                } else if i == 4 {
                    let score = (try cell.text()).replacingOccurrences(of: " Failed Dive", with: "")
                    let updatedScore = (score.replacingOccurrences(of: "Dive Changed", with: ""))
                    netScore = Double(updatedScore)!
                } else if i == 5 {
                    if try cell.text().count > 4 {
                        DD = Double(try cell.text().suffix(4))!
                    } else {
                        DD = Double(try cell.text())!
                    }
                } else if i == 6 {
                    score = Double(try cell.text().replacingOccurrences(of: "  ", with: ""))!
                    scoreLink = "https://secure.meetcontrol.com/divemeets/system/" + (try cell.getElementsByTag("a").attr("href"))
                }
            }
            meetScores[order] = (diveNum, height, name, netScore, DD, score, scoreLink)
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
            print("Could not fetch text")
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
            print("Could not fetch text")
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
            print("Could not fetch text")
        }
    }
}
