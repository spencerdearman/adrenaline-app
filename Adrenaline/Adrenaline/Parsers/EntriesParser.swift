//
//  EntriesParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/28/23.
//

import Foundation
import SwiftSoup

private enum InfoStage {
    case events
    case divers
    case coaches
}

class EntriesParser: ObservableObject {
    @Published var entries: [EventEntry]?
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    func parseEntries(html: String) async throws -> [EventEntry]? {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let content = try body.getElementById("dm_content")
        let tables = try content?.getElementsByTag("table")
        
        var result: [EventEntry]?
        do {
            if tables?.count ?? 0 < 2 { return nil }
            if let rows = try tables?[1].getElementsByTag("tr") {
                var entry: EventEntry = EventEntry()
                for r in rows {
                    let bolds = try r.getElementsByTag("strong")
                    if bolds.count > 0 {
                        let sublinks = try bolds[0].getElementsByTag("a")
                        
                        // Row with diver name and potentially board label
                        if sublinks.count > 0 && sublinks[0].hasAttr("href") {
                            let links = try bolds[0].getElementsByTag("a")
                            
                            if links.count > 1 {
                                let diverAName = try links[0].text().components(separatedBy: ", ")
                                entry.firstName = diverAName[1]
                                entry.lastName = diverAName[0]
                                entry.link = try leadingLink + links[0].attr("href")
                                entry.team = try links[1].text()
                                
                                if links.count > 2 {
                                    let name = try links[2].text().components(separatedBy: ", ")
                                    let first = name[1]
                                    let last = name[0]
                                    let link = try leadingLink + links[2].attr("href")
                                    entry.synchroPartner = SynchroPartner(firstName: first,
                                                                          lastName: last,
                                                                          link: link)
                                }
                            }
                            
                            if bolds.count > 1 {
                                entry.board = try bolds[1].text().components(separatedBy: ": ").last
                            }
                            
                        } else if try bolds[0].text().contains("DD Total") {
                            // Row with DD Total and value
                            if bolds.count > 1 {
                                entry.totalDD = try Double(bolds[1].text())
                            }
                            
                            if result == nil {
                                result = []
                            }
                            result!.append(entry)
                            entry = EventEntry()
                            
                        } else {
                            // Row with headers can be skipped
                            continue
                        }
                    } else {
                        let vals = try r.getElementsByTag("td")
                        if vals.count > 4 {
                            let dive: EntryDive = try EntryDive(
                                number: vals[1].text(),
                                height: Double(String(vals[2].text().dropLast())) ?? 0.0,
                                name: vals[3].text(),
                                dd: Double(vals[4].text()) ?? 0.0)
                            if entry.dives == nil {
                                entry.dives = []
                            }
                            entry.dives!.append(dive)
                        }
                    }
                }
                
                return result
            }
        } catch {
            print("Results page parse failed")
        }
        
        return nil
    }
    
    func parseNamedEntry(html: String, searchName: String) throws -> EventEntry? {
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let content = try body.getElementById("dm_content")
        let tables = try content?.getElementsByTag("table")
        
        do {
            if tables?.count ?? 0 < 2 { return nil }
            if let rows = try tables?[1].getElementsByTag("tr") {
                var entry: EventEntry = EventEntry()
                for r in rows {
                    let bolds = try r.getElementsByTag("strong")
                    if bolds.count > 0 {
                        let sublinks = try bolds[0].getElementsByTag("a")
                        
                        // Row with diver name and potentially board label
                        if sublinks.count > 0 && sublinks[0].hasAttr("href") {
                            let links = try bolds[0].getElementsByTag("a")
                            if links.count > 1 {
                                let name = try links[0].text().components(separatedBy: ", ")
                                
                                // Skips further processing if the name is not the matched name
                                if searchName != (name[0] + ", " + name[1]) { continue }
                                
                                entry.firstName = name[1]
                                entry.lastName = name[0]
                                entry.link = try leadingLink + links[0].attr("href")
                                entry.team = try links[1].text()
                            }
                            
                            if bolds.count > 1 {
                                entry.board = try bolds[1].text().components(separatedBy: ": ").last
                            }
                            
                        } else if try bolds[0].text().contains("DD Total") {
                            // Row with DD Total and value
                            if bolds.count > 1 {
                                entry.totalDD = try Double(bolds[1].text())
                            }
                            
                            return entry
                            
                        } else {
                            // Row with headers can be skipped
                            continue
                        }
                    } else {
                        let vals = try r.getElementsByTag("td")
                        if vals.count > 4 {
                            let dive: EntryDive = try EntryDive(
                                number: vals[1].text(),
                                height: Double(String(vals[2].text().dropLast())) ?? 0.0,
                                name: vals[3].text(),
                                dd: Double(vals[4].text()) ?? 0.0)
                            if entry.dives == nil {
                                entry.dives = []
                            }
                            entry.dives!.append(dive)
                        }
                    }
                }
            }
        } catch {
            print("Entries page by name parse failed")
        }
        
        return nil
    }
    
    func parseProfileUpcomingMeets(html: String) async throws -> [String: [String: String]]? {
        var result: [String: [String: String]] = [:]
        
        let document: Document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let main = try body.getElementsByTag("table")
        
        if main.count < 2 { return nil }
        let overall = try main[1].getElementsByTag("tr")
        var hasUpcomingMeets = false
        
        for (_, t) in overall.enumerated(){
            let tester = try t.getElementsByTag("td")
            if try tester.count >= 3 && tester[2].text().contains("Dive Sheet"){
                hasUpcomingMeets = true
                break
            }
        }
        
        if !hasUpcomingMeets { return nil }
        
        var lastMeet: String = ""
        for row in overall {
            let text = try row.text()
            
            if text.contains("Upcoming Meets") {
                continue
            }
            
            let bold = try row.getElementsByTag("strong")
            // New meet name
            if bold.count > 0 {
                lastMeet = try bold[0].text()
                result[lastMeet] = [:]
            } else {
                let items = try row.getElementsByTag("td")
                if items.count < 3 { return nil }
                let event = try items[0].text()
                    .replacingOccurrences(of: "&nbsp;", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let link = try leadingLink + items[2].getElementsByTag("a").attr("href")
                result[lastMeet]![event] = link
            }
        }
        
        return result
    }
}

struct EntryDive: Hashable {
    var number: String
    var height: Double
    var name: String
    var dd: Double
}

struct EventEntry: Hashable {
    static func == (lhs: EventEntry, rhs: EventEntry) -> Bool {
        return lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName &&
        lhs.team == rhs.team && lhs.link == rhs.link && lhs.dives == rhs.dives &&
        lhs.totalDD == rhs.totalDD && lhs.board == rhs.board
    }
    
    var firstName: String?
    var lastName: String?
    var team: String?
    var link: String?
    var dives: [EntryDive]?
    var totalDD: Double?
    var board: String?
    var synchroPartner: SynchroPartner?
}

struct SynchroPartner: Hashable {
    var firstName: String
    var lastName: String
    var link: String
}
