//
//  ProfileParser.swift
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

struct ProfileMeet: Hashable {
    let name: String
    var events: [ProfileMeetEvent]
}

struct ProfileMeetEvent: Hashable {
    let name: String
    let link: String
    var place: Int?
    var score: Double?
}

struct DiverInfo: Hashable {
    let first: String
    let last: String
    let link: String
    
    var name: String {
        first + " " + last
    }
    var nameLastFirst: String {
        last + ", " + first
    }
    var diverId: String {
        link.components(separatedBy: "=").last ?? ""
    }
}

struct DiveStatistic: Hashable {
    let number: String
    let name: String
    let height: Double
    let highScore: Double
    let highScoreLink: String
    let avgScore: Double
    let avgScoreLink: String
    let numberOfTimes: Int
}

final class ProfileParser: ObservableObject {
    @Published var profileData: ProfileData = ProfileData()
    private let getTextModel = GetTextAsyncModel()
    private let leadingLink: String = "https://secure.meetcontrol.com/divemeets/system/"
    
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
    
    private func otherWrapLooseText(text: String) -> String {
        do {
            var result: String = text
            let minStringLen = 1
            let pattern = "[a-zA-z0-9\\s&;:]+<br>"
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
                                                                 with: "<div>\(trimmedM)</div><br>")
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
    
    private func assignInfoKeys(dict: [String: String]) -> ProfileInfoData? {
        var first: String = ""
        var last: String = ""
        var cityState: String?
        var country: String?
        var gender: String?
        var age: Int?
        var finaAge: Int?
        var diverId: String = ""
        var hsGradYear: Int?
        
        for (key, value) in dict {
            switch key {
                case "Name:":
                    let nameComps = value.split(separator: " ")
                    first = nameComps.dropLast().joined(separator: " ")
                    if let lastSubstring = nameComps.last { last = String(lastSubstring) }
                    break
                case "City/State:", "State:":
                    cityState = value
                    break
                case "Country:":
                    country = value
                    break
                case "Gender:":
                    gender = value
                    break
                case "Age:":
                    age = Int(value)
                    break
                case "FINA Age:":
                    finaAge = Int(value)
                    break
                case "High School Graduation:":
                    hsGradYear = Int(value)
                    break
                case "DiveMeets #:":
                    diverId = value
                    break
                default:
                    break
            }
        }
        
        return ProfileInfoData(first: first, last: last, cityState: cityState, country: country,
                               gender: gender, age: age, finaAge: finaAge,
                               diverId: diverId, hsGradYear: hsGradYear)
    }
    
    private func parseInfo(_ data: Element) -> ProfileInfoData? {
        do {
            var result: [String: String] = [:]
            // Add extra break to help with wrapping loose text
            let dataHtml = try data.html() + "<br>"
            guard let body = try SwiftSoup.parseBodyFragment(otherWrapLooseText(text: dataHtml)).body()
            else { return nil }
            
            var lastKey: String = ""
            let rows = body.children().filter { $0.hasText() && $0.tagName() != "span" }
            for row in rows {
                if row.tagName() == "strong" {
                    lastKey = try row.text()
                    continue
                } else if row.tagName() == "div" {
                    result[lastKey] = try row.text()
                }
            }
            
            return assignInfoKeys(dict: result)
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
            var result: ProfileJudgingData = []
            guard let cleaned = try SwiftSoup.parseBodyFragment(data.html()
                .replacingOccurrences(of: "&nbsp;", with: "")).body() else { return nil }
            let rows = try cleaned.getElementsByTag("tr")
            
            var lastMeetName: String = ""
            var lastMeet: ProfileMeet?
            for row in rows {
                let subRow = try row.getElementsByTag("td")
                if subRow.count == 0 { return nil }
                else if try subRow.count == 1 && subRow[0].text() == "Judging History" { continue }
                else if subRow.count == 1 {
                    if let meet = lastMeet { result.append(meet) }
                    lastMeet = nil
                    lastMeetName = try subRow[0].text()
                    continue
                }
                
                if subRow.count < 2 { return nil }
                
                let eventName = try subRow[0].text().trimmingCharacters(in: .whitespacesAndNewlines)
                guard let linkFirst = try subRow[1].getElementsByTag("a").first() else { return nil }
                let link = try leadingLink + linkFirst.attr("href")
                
                if lastMeet == nil {
                    lastMeet = ProfileMeet(name: lastMeetName, events: [])
                }
                lastMeet?.events.append(ProfileMeetEvent(name: eventName, link: link))
                
            }
            
            if let meet = lastMeet {
                result.append(meet)
            }
            
            return result
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
            let links = try data.getElementsByTag("a")
            
            return try links.map {
                let comps = try $0.text().split(separator: ", ", maxSplits: 1)
                let first = String(comps.last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let last = String(comps.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                return DiverInfo(first: first, last: last, link: try leadingLink + $0.attr("href"))
            }
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
                
                let eventName = try subRow[0].text().trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    private func breakDownHtml(_ html: String) -> [String] {
        if html.contains("DiveMeets #") {
            return html.split(separator: "<br><br>").map { String($0) }
        } else if html.contains("Dive Statistics") &&
                    html.components(separatedBy: "</table>").count > 1 {
            let comps = html.components(separatedBy: "</table>")
                .filter { $0.count > 0 }
                .map { String($0 + "</table>") }
            return comps
        } else {
            return [html]
        }
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
            // Remove unnecessary spacing that sometimes appears and breaks split
            let dataHtml = try data.html().replacingOccurrences(of: "> <", with: "><")
            let bigHtmlBlocks = dataHtml.split(separator: "<br><br><br><br>")
            
            // Separates big html blocks into smaller chunks separated by components of ProfileData
            var htmlComponents: [String] = []
            for elem in bigHtmlBlocks {
                htmlComponents += breakDownHtml(String(elem))
            }
            
            for elem in htmlComponents.filter({ !$0.contains("img src=") }) {
                guard let body = try SwiftSoup.parseBodyFragment(elem).body() else {
                    return false
                }
                
                if elem.contains("DiveMeets #") {
                    await MainActor.run {
                        profileData.info = parseInfo(body)
                    }
                } else if elem.contains("<strong>Diving:</strong>") {
                    await MainActor.run {
                        profileData.diving = parseDivingData(body)
                    }
                } else if elem.contains("<strong>Coaching:</strong>") {
                    await MainActor.run {
                        profileData.coaching = parseCoachingData(body)
                    }
                } else if elem.contains("Upcoming Meets") {
                    await MainActor.run {
                        profileData.upcomingMeets = parseUpcomingMeetsData(body)
                    }
                } else if elem.contains("<span style=\"color: blue\">DIVE</span>") {
                    await MainActor.run {
                        profileData.meetResults = parseMeetResultsData(body)
                    }
                } else if elem.contains("Dive Statistics") {
                    await MainActor.run {
                        profileData.diveStatistics = parseDiveStatistics(body)
                    }
                } else if elem.contains("<center>") {
                    await MainActor.run {
                        profileData.coachDivers = parseCoachDiversData(body)
                    }
                } else if elem.contains("Judging History") {
                    await MainActor.run {
                        profileData.judging = parseJudgingData(body)
                    }
                }
            }
            
            //            print("------------INFO-----------------")
            //            print(profileData.info)
            //            print("------------DIVING-----------------")
            //            print(profileData.diving)
            //            print("------------COACHING-----------------")
            //            print(profileData.coaching)
            //            print("------------UPCOMING-----------------")
            //            print(profileData.upcomingMeets)
            //            print("------------RESULTS-----------------")
            //            print(profileData.meetResults)
            //            print("------------DIVERS-----------------")
            //            print(profileData.coachDivers)
            //            print("------------JUDGING-----------------")
            //            print(profileData.judging)
            
            return true
        } catch {
            print("Failed to parse profile")
        }
        
        return false
    }
}

struct NewProfileParserView: View {
    let p: ProfileParser = ProfileParser()
    //    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=12882"
    //    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=101707"
    //    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=13605"
    let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=44388"
    
    var body: some View {
        NavigationView {
            ProfileView(profileLink: profileLink)
        }
    }
}
