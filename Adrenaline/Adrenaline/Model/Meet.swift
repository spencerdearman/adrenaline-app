//
//  Meet.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import Foundation
import SwiftUI
import RegexBuilder

struct MeetEvent: Hashable, Identifiable {
    let id = UUID()
    let name: String
    var place: Int?
    var score: Double?
    var children: [MeetEvent]?
    var isOpen: Bool = false
    var isExpanded: Bool = false
    var isChild: Bool = false
    var link: String?
    var firstNavigation: Bool = true
}

struct MeetBase: Hashable, Identifiable {
    let id = UUID()
    let name: String
    var org: String?
    var location: String?
    var date: String?
    var link: String?
    var resultsLink: String?
}

extension MeetBase {
    static func from(meetEvent: MeetEvent) async -> MeetBase? {
        do {
            let getTextModel = GetTextAsyncModel()
            let mpp: MeetPageParser = MeetPageParser()
            guard let link = meetEvent.link else { return nil }
            
            // Initialize meet parse from index page
            let infoUrl: URL?
            let resultsUrl: URL?
            if link.contains("meetinfo") {
                infoUrl = URL(string: link)
                resultsUrl = URL(string: link.replacingOccurrences(of: "meetinfo", with: "meetresults"))
            } else if link.contains("meetresults") {
                infoUrl = URL(string: link.replacingOccurrences(of: "meetresults", with: "meetinfo"))
                resultsUrl = URL(string: link)
            } else {
                print("link did not conform to the proper structure")
                return nil
            }
            
            if let url = infoUrl {
                // This sets getTextModel's text field equal to the HTML from url
                await getTextModel.fetchText(url: url)
                
                if let html = getTextModel.text {
                    let meetData = try await mpp.parseMeetPage(link: url.absoluteString, html: html)
                    if let meetData = meetData {
                        guard let meetInfoData = await mpp.getMeetInfoData(data: meetData)?.0 else {
                            return nil
                        }
                        
                        print("meetInfoData:", meetInfoData)
                        
                        var location: String? = nil
                        let locationRef = Reference(Substring.self)
                        
                        // Extract city, state from pool address
                        if let pool = meetInfoData["Pool"],
                           let result = pool.firstMatch(of: Regex {
                               Capture(as: locationRef) {
                                   /[A-Za-z \'-]+, [A-Za-z]{2}/
                               }
                           }) {
                            location = String(result[locationRef])
                        }
                        
                        // Compute display date if it exists and reformat it to remove day of week
                        var date: String? = nil
                        if let start = meetInfoData["Start Date"],
                           let end = meetInfoData["End Date"] {
                            let df = DateFormatter()
                            df.dateFormat = "EEEE, MMM d, yyyy"
                            
                            if let startDate = df.date(from: start),
                               let endDate = df.date(from: end) {
                                df.dateFormat = "MMM d, yyyy"
                                date = getDisplayDateString(start: df.string(from: startDate),
                                                            end: df.string(from: endDate))
                            }
                        }
                        
                        return MeetBase(name: meetInfoData["Name"] ?? "",
                                        location: location,
                                        date: date,
                                        link: url.absoluteString,
                                        resultsLink: resultsUrl?.absoluteString)
                    } else {
                        print("Meet page failed to parse")
                        return nil
                    }
                }
            }
        } catch {
            print("Failed to create MeetBase")
        }
        
        return nil
    }
}
