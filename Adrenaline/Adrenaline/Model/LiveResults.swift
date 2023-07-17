//
//  LiveResults.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 4/7/23.
//

import Foundation

struct LiveResultsDiver {
    var name: String
    var dive: String
    // TODO:
}

struct LiveResults {
    var meetName: String
    var eventName: String
    var link: String
    var currentRound: Int?
    var totalRounds: Int?
    var currentDiver: LiveResultsDiver?
    var lastDiver: LiveResultsDiver?
    var rows: [[String: String]]
    var isFinished: Bool
    
    init(meetName: String, eventName: String, link: String, currentRound: Int? = nil,
         totalRounds: Int? = nil, currentDiver: LiveResultsDiver? = nil,
         lastDiver: LiveResultsDiver? = nil, rows: [[String: String]] = [], isFinished: Bool) {
        self.meetName = meetName
        self.eventName = eventName
        self.link = link
        self.currentRound = currentRound
        self.totalRounds = totalRounds
        self.currentDiver = currentDiver
        self.lastDiver = lastDiver
        self.rows = rows
        self.isFinished = isFinished
    }
}
