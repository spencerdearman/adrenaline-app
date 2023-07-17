//
//  NewProfileParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/14/23.
//

import Foundation
import SwiftSoup
import SwiftUI

//                            [org   : Team info]
typealias ProfileDivingData = [String: Team]
//                              [org   : Team info] Note: coach name and link in Team is same
//                                                        person as currently parse profile
typealias ProfileCoachingData = [String: Team]
// List of profile meets and their corresponding events, not using the place and score fields
typealias ProfileJudgingData = [ProfileMeet]
// List of profile meets and their corresponding events, where the link is the sheet and score
// and place fields are unused
typealias ProfileUpcomingMeetsData = [ProfileMeet]
// DiverInfo contains a diver name and link
typealias ProfileCoachDiversData = [DiverInfo]
// List of profile meets and their corresponding events, also using the place and score fields
typealias ProfileMeetResultsData = [ProfileMeet]
// List of DiveStatistic objects from DiveStatistics table
typealias ProfileDiveStatisticsData = [DiveStatistic]

struct ProfileData {
    var info: ProfileInfoData?
    var diving: ProfileDivingData?
    var coaching: ProfileCoachingData?
    var judging: ProfileJudgingData?
    var upcomingMeets: ProfileUpcomingMeetsData?
    var diveStatistics: ProfileDiveStatisticsData?
    var coachDivers: ProfileCoachDiversData?
    var meetResults: ProfileMeetResultsData?
}

struct ProfileInfoData {
    let first: String
    let last: String
    let cityState: String?
    let country: String?
    let gender: String?
    let age: Int?
    let finaAge: Int?
    let diverId: String
    let hsGradYear: Int?
    
    var name: String {
        first + " " + last
    }
    var nameLastFirst: String {
        last + ", " + first
    }
}

struct Team {
    let name: String
    let coachName: String
    let coachLink: String
}

struct ProfileMeet {
    let name: String
    var events: [ProfileMeetEvent]
}

struct ProfileMeetEvent {
    let name: String
    let link: String
    var place: Int?
    var score: Double?
}

struct DiverInfo {
    let name: String
    let link: String
    
    var diverId: String {
        link.components(separatedBy: "=").last ?? ""
    }
}

struct DiveStatistic {
    let number: String
    let name: String
    let height: Double
    let highScore: Double
    let highScoreLink: String
    let avgScore: Double
    let avgScoreLink: String
    let numberOfTimes: Int
}

final class NewProfileParser: ObservableObject {
    @Published var profileData: ProfileData = ProfileData()
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
    private func getNameComponents(_ text: String) -> [String]? {
        // Case where only State label is provided
        var comps = text.slice(from: "Name: ", to: " State:")
        if comps == nil {
            // Case where City/State label is provided
            comps = text.slice(from: "Name: ", to: " City/State:")
            
            if comps == nil {
                // Case where no labels are provided (shell profile)
                comps = text.slice(from: "Name: ", to: " DiveMeets ID:")
            }
        }
        
        guard let comps = comps else { return nil }
        
        return comps.components(separatedBy: " ")
    }
    
    private func wrapLooseText(text: String) -> String {
        do {
            var result: String = text
            let minStringLen = "<br>".count
            let pattern = "<br>[a-zA-z0-9\\s&;:]+"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(text.startIndex..<text.endIndex,
                                  in: text)
            var seen: Set<Substring> = Set<Substring>()
            regex.enumerateMatches(in: text, range: nsrange) {
                (match, _, _) in
                guard let match = match else { return }
                
                for i in 0..<match.numberOfRanges {
                    if let range = Range(match.range(at: i), in: text) {
                        let m = text[range]
                        let trimmedM = m.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "&nbsp;", with: "")
                            .replacingOccurrences(of: "<br>", with: "")
                        
                        if trimmedM.count > minStringLen {
                            if seen.contains(m) {
                                continue
                            }
                            result = result.replacingOccurrences(of: m,
                                                                 with: "<br><div>\(trimmedM)</div>")
                            seen.insert(m)
                        }
                    }
                }
            }
            return result
        } catch {
            print("Failed to parse text input")
        }
        
        return ""
    }
    
    private func parseInfo(_ data: Element) -> ProfileInfoData? {
        do {
            let text = try data.text()
            guard let nameComps = getNameComponents(text) else { return nil }
            let first = nameComps.dropLast().joined(separator: " ")
            let last = nameComps.last ?? ""
            let cityState = text.slice(from: "State: ", to: " Country")
            let country = text.slice(from: " Country: ", to: " Gender")
            let gender = text.slice(from: " Gender: ", to: " Age")
            let age = text.slice(from: " Age: ", to: " FINA")
            let lastSliceText: String
            if text.contains("High School Graduation") {
                lastSliceText = "High School Graduation"
            } else {
                lastSliceText = "DiveMeets"
            }
            
            let fina = String((text.slice(from: " FINA Age: ", to: lastSliceText) ?? "").prefix(2))
            var hsGrad: String? = nil
            if lastSliceText == "High School Graduation" {
                hsGrad = text.slice(from: " High School Graduation: ", to: "DiveMeets")?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            guard let diverId = text.slice(from: "DiveMeets #: ") else { return nil }
            
            return ProfileInfoData(first: first, last: last, cityState: cityState, country: country,
                                   gender: gender, age: Int(age ?? ""), finaAge: Int(fina),
                                   diverId: diverId, hsGradYear: Int(hsGrad ?? ""))
        } catch {
            print("Failed to parse info")
        }
        
        return nil
    }
    
    private func parseDivingData(_ data: Element) -> ProfileDivingData? {
        var result: ProfileDivingData = [:]
        do {
            let doc = try SwiftSoup.parseBodyFragment(wrapLooseText(text: data.html()))
            guard let body = doc.body() else { return nil }
            let elems = body.children().filter { a in a.hasText() }
            
            var key: String = ""
            var teamName: String = ""
            for elem in elems {
                let text = try elem.text()
                if text == "Diving:" { continue }
                if elem.tagName() == "strong" {
                    key = String(text.dropLast())
                } else if elem.tagName() == "div" && !text.contains("Coach:") {
                    teamName = text
                } else if elem.tagName() == "a" {
                    let coachNameText = try elem.text()
                    let comps = coachNameText.components(separatedBy: " ")
                    guard let first = comps.last else { return nil }
                    let last = comps.dropLast().joined(separator: " ")
                    result[key] = Team(name: teamName,
                                       coachName: first + " " + last,
                                       coachLink: try leadingLink + elem.attr("href"))
                }
            }
            
            return result
        } catch {
            print("Failed to parse diving data")
        }
        
        return nil
    }
    
    private func parseCoachingData(_ data: Element) -> ProfileCoachingData? {
        var result: ProfileCoachingData = [:]
        do {
            let doc = try SwiftSoup.parseBodyFragment(wrapLooseText(text: data.html()))
            guard let body = doc.body() else { return nil }
            let elems = body.children().filter { a in a.hasText() }
            
            var key: String = ""
            var teamName: String = ""
            for elem in elems {
                let text = try elem.text()
                if text == "Coaching:" { continue }
                if elem.tagName() == "strong" {
                    key = String(text.dropLast())
                } else if elem.tagName() == "div" {
                    teamName = text
                } else if elem.tagName() == "a" {
                    result[key] = Team(name: teamName,
                                       coachName: "",
                                       coachLink: try leadingLink + elem.attr("href"))
                }
            }
            
            return result
        } catch {
            print("Failed to parse coaching data")
        }
        
        return nil
    }
    
    private func parseJudgingData(_ data: Element) -> ProfileJudgingData? {
        do {
            print("Judging")
            print(try data.text())
        } catch {
            print("Failed to parse judging data")
        }
        return nil
    }
    
    private func parseUpcomingMeetsData(_ data: Element) -> ProfileUpcomingMeetsData? {
        do {
            var result: ProfileUpcomingMeetsData = []
            let rows = try data.getElementsByTag("tr")
            
            var lastMeetName: String = ""
            var lastMeet: ProfileMeet?
            for row in rows {
                let subRow = try row.getElementsByTag("td")
                if try subRow.count == 1 && subRow[0].text() == "Upcoming Meets" { continue }
                else if subRow.count == 1 {
                    if let meet = lastMeet { result.append(meet) }
                    lastMeet = nil
                    lastMeetName = try subRow[0].text()
                    continue
                }

                if subRow.count < 3 { return nil }
                let name = try subRow[0].text()
                    .replacingOccurrences(of: "&nbsp;", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard let anchor = try subRow[2].getElementsByTag("a").first() else { return nil }
                let link = try anchor.attr("href")
                
                if lastMeet == nil {
                    lastMeet = ProfileMeet(name: lastMeetName, events: [])
                }
                lastMeet?.events.append(ProfileMeetEvent(name: name, link: leadingLink + link))
            }
            
            if let meet = lastMeet {
                result.append(meet)
            }
            
            return result
            
        } catch {
            print("Failed to parse upcoming meets")
        }
        return nil
    }
    
    private func parseDiveStatistics(_ data: Element) -> ProfileDiveStatisticsData? {
        do {
            var result: ProfileDiveStatisticsData = []
            let rows = try data.getElementsByAttribute("bgcolor")
            
            for row in rows {
                let subRow = try row.getElementsByTag("td")
                if subRow.count != 6 { return nil }
                
                let number = try subRow[0].text()
                guard let height = try Double(subRow[1].text().dropLast()) else { return nil }
                let name = try subRow[2].text()
                guard let highScore = try Double(subRow[3].text()) else { return nil }
                guard let highScoreLink = try subRow[3].getElementsByTag("a").first()?.attr("href")
                else { return nil }
                guard let avgScore = try Double(subRow[4].text()) else { return nil }
                guard let avgScoreLink = try subRow[4].getElementsByTag("a").first()?.attr("href")
                else { return nil }
                guard let numberOfTimes = try Int(subRow[5].text()) else { return nil }
                
                result.append(DiveStatistic(number: number, name: name, height: height,
                                            highScore: highScore,
                                            highScoreLink: leadingLink + highScoreLink,
                                            avgScore: avgScore,
                                            avgScoreLink: leadingLink + avgScoreLink,
                                            numberOfTimes: numberOfTimes))
            }
            
            return result
        } catch {
            print("Failed to parse dive statistics")
        }
        
        return nil
    }
    
    private func parseCoachDiversData(_ data: Element) -> ProfileCoachDiversData? {
        do {
            print("Coach Divers")
            print(try data.text())
        } catch {
            print("Failed to parse coach divers")
        }
        return nil
    }
    
    private func parseMeetResultsData(_ data: Element) -> ProfileMeetResultsData? {
        do {
            var result: ProfileMeetResultsData = []
            guard let cleaned = try SwiftSoup.parseBodyFragment(data.html()
                .replacingOccurrences(of: "&nbsp;", with: "")).body() else { return nil }
            let rows = try cleaned.getElementsByTag("tr")
            
            var lastMeetName: String = ""
            var lastMeet: ProfileMeet?
            for row in rows {
                let subRow = try row.getElementsByTag("td")
                if subRow.count < 1 { return nil }
                else if subRow.count == 1 {
                    if let meet = lastMeet { result.append(meet) }
                    lastMeet = nil
                    lastMeetName = try subRow[0].text()
                    continue
                }
                
                if subRow.count < 3 { return nil }
                
                let eventName = try subRow[0].html().trimmingCharacters(in: .whitespacesAndNewlines)
                let place = try Int(subRow[1].text())
                let score = try Double(subRow[2].text())
                guard let scoreFirst = try subRow[2].getElementsByTag("a").first() else { return nil }
                let scoreLink = try leadingLink + scoreFirst.attr("href")
                
                if lastMeet == nil {
                    lastMeet = ProfileMeet(name: lastMeetName, events: [])
                }
                lastMeet?.events.append(ProfileMeetEvent(name: eventName, link: scoreLink,
                                                         place: place, score: score))
                
            }
            
            if let meet = lastMeet {
                result.append(meet)
            }
            
            return result
        } catch {
            print("Failed to parse meet results")
        }
        return nil
    }
    
    func parseProfile(link: String) async -> Bool {
        do {
            guard let url = URL(string: link) else { return false }
            
            // This sets getTextModel's text field equal to the HTML from url
            await getTextModel.fetchText(url: url)
            guard let html = getTextModel.text else { return false }
            
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else { return false }
            
            let content = try body.getElementsByTag("td")
            if content.isEmpty() { return false }
            
            let data = content[0]
            let dataHtml = try data.html()
            let htmlSplit = dataHtml.split(separator: "<br><br><br><br>")
            if htmlSplit.count > 0 {
                let topHtml = String(htmlSplit[0])
                let topSplit = topHtml.split(separator: "<br><br><br>")
                if topSplit.count > 0 {
                    let infoHtml = String(topSplit[0])
                    guard let body = try SwiftSoup.parseBodyFragment(infoHtml).body() else {
                        return false
                    }
                    profileData.info = parseInfo(body)
                }
                
                if topSplit.count > 1 {
                    let bottomSplit = String(topSplit[1]).split(separator: "<br><br>")
                    for elem in bottomSplit {
                        guard let body = try SwiftSoup.parseBodyFragment(String(elem)).body() else {
                            return false
                        }
                        
                        if elem.contains("<strong>Diving:</strong>") {
                            profileData.diving = parseDivingData(body)
                        } else if elem.contains("<strong>Coaching:</strong>") {
                            profileData.coaching = parseCoachingData(body)
                        }
                    }
                }
                
                if htmlSplit.count > 1 {
                    let tableSplit = String(htmlSplit[1]).split(separator: "</table><br><br>")
//                    print(tableSplit)
                    
                    // There is a <br><br> inside of meet results table, so this gets around that
//                    var foundMeetResults: Bool = false
                    for elem in tableSplit {
//                        print(elem)
//                        print("-------------")
                        guard let body = try SwiftSoup.parseBodyFragment(String(elem)).body() else {
                            return false
                        }
//                        print(body)
                        
                        if elem.contains("Upcoming Meets") {
                            profileData.upcomingMeets = parseUpcomingMeetsData(body)
                        } else if elem.contains("<span style=\"color: blue\">DIVE</span>") {
                            profileData.meetResults = parseMeetResultsData(body)
                        } else if elem.contains("Dive Statistics") {
                            profileData.diveStatistics = parseDiveStatistics(body)
                        }
                            
                    }
                }
                
                if htmlSplit.count > 2 {
                    guard let body = try SwiftSoup.parseBodyFragment(String(htmlSplit[2])).body() else {
                        return false
                    }
//                    print("Coaches Divers")
//                    print(body)
                    profileData.coachDivers = parseCoachDiversData(body)
                }
                
                if htmlSplit.count > 3 {
                    guard let body = try SwiftSoup.parseBodyFragment(String(htmlSplit[3])).body() else {
                        return false
                    }
                    
                    profileData.judging = parseJudgingData(body)
                }
            }
            
            print(profileData.diveStatistics)
            return true
        } catch {
            print("Failed to parse profile")
        }
        
        return false
    }
}

struct NewProfileParserView: View {
    let p: NewProfileParser = NewProfileParser()
    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=12882"
//    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=101707"
    
    var body: some View {
        
        ZStack {}
            .onAppear {
            Task {
                await p.parseProfile(link: profileLink)
            }
        }
    }
}
