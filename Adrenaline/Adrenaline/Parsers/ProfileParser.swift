//
//  ProfileParser.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/29/23.
//

import SwiftUI
import SwiftSoup

// [Organization: [Team: (Coach, CoachLink)]]
typealias DivingDict = [String: [String: (String, String)]]
// [Organization: Team]
typealias CoachingDict = [String: String]
// [Organization]
typealias JudgingDict = [String]
// [(Diver, DiverLink)]
typealias DiverList = [(String, String)]

private enum Stage {
    case diving
    case coaching
    case judging
    case diverList
    case notSet
}

final class ProfileParser: ObservableObject {
    
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
                        
                        if trimmedM.count > minStringLen {
                            if seen.contains(m) {
                                continue
                            }
                            result = result.replacingOccurrences(of: m, with: "<div>" + m + "</div>")
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
    
    private func isHeader(_ elem: Element) -> Bool {
        let headers: Set<String> = Set<String>(["Diving:", "Coaching:", "Judging:"])
        do {
            return try elem.tagName() == "strong" && headers.contains(elem.text())
        } catch {
            return false
        }
    }
    
    private func getStage(_ elem: Element) -> Stage? {
        if !isHeader(elem) {
            return nil
        }
        do {
            switch try elem.text() {
                case "Diving:":
                    return .diving
                case "Coaching:":
                    return .coaching
                case "Judging:":
                    return .judging
                default:
                    return nil
            }
        } catch {
            print("Error getting element text")
        }
        return nil
    }
    
    private func partialToFullLink(_ link: String) -> String {
        return "https://secure.meetcontrol.com/divemeets/system/" + link
    }
    
    private func coachLinkToFullLink(_ link: String) -> String {
        if !link.hasPrefix("profilec") {
            print("Link is not a Coach Profile, returning empty string")
            return ""
        }
        let delIndex = link.index(link.startIndex, offsetBy: 7)
        return partialToFullLink(link.replacingCharacters(in: delIndex...delIndex, with: ""))
    }
    
    func parseProfile(html: String) -> (DivingDict?, CoachingDict?, JudgingDict?, DiverList?) {
        var diving: DivingDict?
        var coaching: CoachingDict?
        var judging: JudgingDict?
        var diverList: DiverList?
        var stage: Stage = .notSet
        
        do {
            let document: Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                return (nil, nil, nil, nil)
            }
            
            let rows = try body.getElementsByTag("td")
            if let first = rows.first() {
            
            let doc: Document = try SwiftSoup.parseBodyFragment(
                wrapLooseText(text: try first.html()))
            guard let wrappedText = doc.body()?.children() else {
                return (nil, nil, nil, nil)
            }
            
            var keepRows: [Element] = []
            for r in wrappedText {
                let tag = r.tagName()
                if tag == "table" {
                    break
                } else if tag == "br" || tag == "img" || tag == "span" {
                    continue
                } else {
                    keepRows.append(r)
                }
            }
            
            var i = 0
            while i < keepRows.count {
                let r = keepRows[i]
                if r.tagName() == "center" {
                    stage = .diverList
                    i += 1
                    continue
                } else if isHeader(r) {
                    stage = getStage(r)!
                    i += 1
                    continue
                } else if stage == .notSet {
                    i += 1
                    continue
                }
                
                switch stage {
                    case .diving:
                        do {
                            let org = try String(r.text().dropLast())
                            let team = try keepRows[i+1].text()
                            let coach = try keepRows[i+3].text()
                            let link = try coachLinkToFullLink(
                                keepRows[i+3].attr("href"))
                            if diving == nil {
                                diving = [:]
                            }
                            if !diving!.keys.contains(org) {
                                diving![org] = [:]
                            }
                            diving![org]![team] = (coach, link)
                        } catch {
                            print("Failed to convert Element to String in Diving")
                        }
                        i += 4
                    case .coaching:
                        do {
                            let org = try String(r.text().dropLast())
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            let team = try keepRows[i+1].text()
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if coaching == nil {
                                coaching = [:]
                            }
                            coaching![org] = team
                        } catch {
                            print("Failed to convert Element to String in Coaching")
                        }
                        i += 3
                    case .judging:
                        do {
                            if judging == nil {
                                judging = []
                            }
                            try judging?.append(r.text()
                                .trimmingCharacters(in: .whitespacesAndNewlines))
                        } catch {
                            print("Failed to convert Element to String in Judging")
                        }
                        i += 1
                    case .diverList:
                        do {
                            let name = try r.text()
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            let link = try partialToFullLink(r.attr("href"))
                            
                            if diverList == nil {
                                diverList = []
                            }
                            diverList?.append((name, link))
                        } catch {
                            print("Failed to convert Element to String in DiverList")
                        }
                        i += 1
                    case .notSet:
                        print("Reached impossible state, returning nil")
                        return (nil, nil, nil, nil)
                }
            }
            }
        } catch {
            print("Error parsing profile")
        }
        
        return (diving, coaching, judging, diverList)
    }
    
    // Wraps caching functionality into getting profile HTML to avoid network access if not necessary
    func getProfileHTML(profileLink: String) -> String {
        let session = URLSession.shared
        let diverID: String = profileLink.components(separatedBy: "=").last ?? ""
//        String(
//            profileLink[(profileLink.components(separatedBy: "=").last ?? "")])
        if let url = URL(string: profileLink) {
        
            var resultText: String?
            
            // Checks cache first to see if there is a value already loaded, avoids network
            guard let cachedData = GlobalCaches.caches["profileHTML"]![diverID] as? String else {
                print("cachedData is nil")
                let sem = DispatchSemaphore.init(value: 0)
                let task = session.dataTask(with: url) { data, response, error in
                    defer { sem.signal() }
                    // Check whether data is not nil
                    guard let loadedData = data else { return }
                    // Load HTML code as string
                    if let text = String(data: loadedData, encoding: .utf8) {
                        
                        // Adds HTML to cache
                        GlobalCaches.caches["profileHTML"]![diverID] = text
                        resultText = text
                    }
                }
                task.resume()
                sem.wait()
                
                return resultText ?? ""
            }
            
            print("cachedData is not nil")
            return cachedData
        }
        
        return ""
    }
}

struct ProfileParserView: View {
    var text: String = ""
    let p: ProfileParser = ProfileParser()
    var body: some View {
        
        Button("Button") {
            let profileLink: String = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=13605"
            var diving: DivingDict?
            var coaching: CoachingDict?
            var judging: JudgingDict?
            var diverList: DiverList?
            
            // Get profile html here instead of using URL directly
            let html = p.getProfileHTML(profileLink: profileLink)
            (diving, coaching, judging, diverList) = p.parseProfile(html: html)
            print(diving ?? [:], coaching ?? [:], judging ?? [], diverList ?? [])
        }
    }
}
