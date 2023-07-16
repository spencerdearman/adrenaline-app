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
//                                   [meet  : [event : entry]]
typealias ProfileUpcomingMeetsData = [String: [String: EventEntry]]
// DiverInfo contains a diver name and link
typealias ProfileCoachDiversData = [DiverInfo]
// List of profile meets and their corresponding events, also using the place and score fields
typealias ProfileMeetResultsData = [ProfileMeet]

struct ProfileData {
    var info: ProfileInfoData?
    var diving: ProfileDivingData?
    var coaching: ProfileCoachingData?
    var judging: ProfileJudgingData?
    var upcomingMeets: ProfileUpcomingMeetsData?
    var coachDivers: ProfileCoachDiversData?
    var meetResults: ProfileMeetResultsData?
}

struct ProfileInfoData {
    let first: String
    let last: String
    let cityState: String?
    let country: String?
    let gender: String?
    let age: String?
    let finaAge: String?
    let diverId: String
    let hsGradYear: String?
    
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
    let place: String?
    let score: String?
}

struct DiverInfo {
    let name: String
    let link: String
    
    var diverId: String {
        link.components(separatedBy: "=").last ?? ""
    }
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
                hsGrad = text.slice(from: " High School Graduation: ", to: "DiveMeets")
            }
            
            guard let diverId = text.slice(from: "DiveMeets #: ") else { return nil }
            
            return ProfileInfoData(first: first, last: last, cityState: cityState, country: country,
                                   gender: gender, age: age, finaAge: fina, diverId: diverId,
                                   hsGradYear: hsGrad)
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
        return nil
    }
    
    private func parseJudgingData(_ data: Element) -> ProfileJudgingData? {
        return nil
    }
    
    private func parseUpcomingMeetsData(_ data: Element) -> ProfileUpcomingMeetsData? {
        return nil
    }
    
    private func parseCoachDiversData(_ data: Element) -> ProfileCoachDiversData? {
        return nil
    }
    
    private func parseMeetResultsData(_ data: Element) -> ProfileMeetResultsData? {
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
                            profileData.coaching = parseCoachingData(data)
                        }
                    }
                }
            }
            
//            for elem in htmlSplit {
//                print(elem)
//                print("----------------------------")
//            }
            print(profileData)
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
    
    var body: some View {
        
        Button("Button") {
            Task {
                await p.parseProfile(link: profileLink)
            }
        }
    }
}
