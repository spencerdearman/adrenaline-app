//
//  SkillRating.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/20/23.
//

import Foundation

final class SkillRating {
    let diveStatistics: ProfileDiveStatisticsData
    let diveTableData: [String: DiveData]? = getDiveTableData()
    
    init(diveStatistics: ProfileDiveStatisticsData) {
        self.diveStatistics = diveStatistics
    }
    
    // Separates ProfileDiveStatisticsData into three sets separated by event (1M, 3M, Platform)
    func getDiverStatsByEvent() -> (Set<DiveStatistic>, Set<DiveStatistic>, Set<DiveStatistic>) {
        var oneDives: Set<DiveStatistic> = Set<DiveStatistic>()
        var threeDives: Set<DiveStatistic> = Set<DiveStatistic>()
        var platformDives: Set<DiveStatistic> = Set<DiveStatistic>()
        
        for dive in diveStatistics {
            if dive.height > 3 {
                platformDives.insert(dive)
            } else if dive.height > 1 {
                threeDives.insert(dive)
            } else {
                oneDives.insert(dive)
            }
        }
        
        return (oneDives, threeDives, platformDives)
    }
    
    // Computes average score times DD for a given dive
    func computeSkillValue(_ dive: DiveStatistic) -> Double {
        return dive.avgScore * (getDiveDD(data: diveTableData ?? [:], forKey: dive.number,
                                          height: dive.height) ?? 0.0)
    }
    
    func isSameDiveNumber(a: DiveStatistic, b: DiveStatistic?) -> Bool {
        if let b = b, a.number.dropLast() == b.number.dropLast() { return true }
        return false
    }
    
    func getBestDive(dive: DiveStatistic, stored: DiveStatistic?) -> DiveStatistic? {
        if let s = stored {
            let diveValue = computeSkillValue(dive)
            let curValue = computeSkillValue(s)
            
            if diveValue > curValue ||
                (diveValue == curValue && dive.numberOfTimes > s.numberOfTimes) {
                return dive
            }
        } else {
            return dive
        }
        
        return stored
    }
    
    // Gets top six dives from given set of statistics
    // Note: set of dives should be passed in after filtering by event
    func getTopDives(dives: Set<DiveStatistic>) -> [DiveStatistic?] {
        var front: DiveStatistic?
        var back: DiveStatistic?
        var reverse: DiveStatistic?
        var inward: DiveStatistic?
        var twist: DiveStatistic?
        var armstand: DiveStatistic?
        var sixth: DiveStatistic?
        
        var secondFront: DiveStatistic?
        var secondBack: DiveStatistic?
        var secondReverse: DiveStatistic?
        var secondInward: DiveStatistic?
        var secondTwist: DiveStatistic?
        var secondArmstand: DiveStatistic?
        
        for dive in dives {
            switch dive.number.first {
                case "1":
                    if let f = front {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(f)
                        
                        // Incoming dive is best front seen so far
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > f.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: front) {
                                secondFront = front
                            }
                            front = dive
                        // Incoming dive is not better than best, but could be better than second
                        // best
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondFront) {
                                secondFront = getBestDive(dive: dive, stored: secondFront)
                            }
                        }
                    } else {
                        front = dive
                    }
                case "2":
                    if let b = back {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(b)
                        
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > b.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: back) {
                                secondBack = back
                            }
                            back = dive
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondBack) {
                                secondBack = getBestDive(dive: dive, stored: secondBack)
                            }
                        }
                    } else {
                        back = dive
                    }
                case "3":
                    if let r = reverse {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(r)
                        
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > r.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: reverse) {
                                secondReverse = reverse
                            }
                            reverse = dive
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondReverse) {
                                secondReverse = getBestDive(dive: dive, stored: secondReverse)
                            }
                        }
                    } else {
                        reverse = dive
                    }
                case "4":
                    if let i = inward {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(i)
                        
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > i.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: inward) {
                                secondInward = inward
                            }
                            inward = dive
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondInward) {
                                secondInward = getBestDive(dive: dive, stored: secondInward)
                            }
                        }
                    } else {
                        inward = dive
                    }
                case "5":
                    if let t = twist {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(t)
                        
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > t.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: twist) {
                                secondTwist = twist
                            }
                            twist = dive
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondTwist) {
                                secondTwist = getBestDive(dive: dive, stored: secondTwist)
                            }
                        }
                    } else {
                        twist = dive
                    }
                case "6":
                    if let a = armstand {
                        let diveValue = computeSkillValue(dive)
                        let curValue = computeSkillValue(a)
                        
                        if diveValue > curValue ||
                            (diveValue == curValue && dive.numberOfTimes > a.numberOfTimes) {
                            // Only shifts down best into second best if they don't match dive nums,
                            // otherwise leaves second best empty
                            if !isSameDiveNumber(a: dive, b: armstand) {
                                secondArmstand = armstand
                            }
                            armstand = dive
                        } else {
                            // Only replaces second best if the dive nums are different
                            if !isSameDiveNumber(a: dive, b: secondArmstand) {
                                secondArmstand = getBestDive(dive: dive, stored: secondArmstand)
                            }
                        }
                    } else {
                        armstand = dive
                    }
                default:
                    break
            }
        }
        
        for dive in [secondFront, secondBack, secondReverse, secondInward, secondTwist,
                     secondArmstand] {
            guard let dive = dive else { continue }
            sixth = getBestDive(dive: dive, stored: sixth)
        }
        
        return [front, back, reverse, inward, twist, sixth]
    }
}
