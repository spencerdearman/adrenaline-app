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
    
    init(diveStatistics: ProfileDiveStatisticsData? = nil) {
        if let diveStatistics = diveStatistics {
            self.diveStatistics = diveStatistics
        } else {
            self.diveStatistics = []
        }
    }
    
    // Separates ProfileDiveStatisticsData into three sets separated by event (1M, 3M, Platform)
    private func getDiverStatsByEvent() -> ([DiveStatistic], [DiveStatistic], [DiveStatistic]) {
        var oneDives: [DiveStatistic] = []
        var threeDives: [DiveStatistic] = []
        var platformDives: [DiveStatistic] = []
        
        for dive in diveStatistics {
            if dive.height > 3 {
                platformDives.append(dive)
            } else if dive.height > 1 {
                threeDives.append(dive)
            } else {
                oneDives.append(dive)
            }
        }
        
        return (oneDives, threeDives, platformDives)
    }
    
    // Used by SkillGraph to compute the stats by category of a given diver
    func getDiverStatsByCategory() -> [Int: [DiveStatistic]] {
        var result: [Int: [DiveStatistic]] = [:]
        
        for dive in diveStatistics {
            guard let key = Int(dive.number.prefix(1)) else { return [:] }
            if !result.keys.contains(key) {
                result[key] = []
            }
            
            result[key]!.append(dive)
        }
        
        return result
    }
    
    // Computes average score times DD for a given dive
    private func computeSkillValue(_ dive: DiveStatistic) -> Double {
        return dive.avgScore * (getDiveDD(data: diveTableData ?? [:], forKey: dive.number,
                                          height: dive.height) ?? 0.0)
    }
    
    private func isSameDiveNumber(a: DiveStatistic, b: DiveStatistic?) -> Bool {
        if let b = b, a.number.dropLast() == b.number.dropLast() { return true }
        return false
    }
    
    private func getBestDive(dive: DiveStatistic, stored: DiveStatistic?) -> DiveStatistic? {
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
    private func getTopDives(dives: [DiveStatistic]) -> [DiveStatistic] {
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
                            if !isSameDiveNumber(a: dive, b: front),
                               !isSameDiveNumber(a: dive, b: secondFront) {
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
                            if !isSameDiveNumber(a: dive, b: back),
                               !isSameDiveNumber(a: dive, b: secondBack){
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
                            if !isSameDiveNumber(a: dive, b: reverse),
                               !isSameDiveNumber(a: dive, b: secondReverse) {
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
                            if !isSameDiveNumber(a: dive, b: inward),
                               !isSameDiveNumber(a: dive, b: secondInward) {
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
                            if !isSameDiveNumber(a: dive, b: twist),
                               !isSameDiveNumber(a: dive, b: secondTwist) {
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
                            if !isSameDiveNumber(a: dive, b: armstand),
                               !isSameDiveNumber(a: dive, b: secondArmstand) {
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
        
        let final = [front, back, reverse, inward, twist, sixth]
        var result: [DiveStatistic] = []
        for r in final {
            guard let r = r else { continue }
            result.append(r)
        }
        
        return result
    }
    
    private func invertedNumberOfTimes(num: Int) -> Double {
        return 1.01 - (1.0 / Double(num))
    }
    
    private func computeMetric1(dives: [DiveStatistic]) -> Double {
        var sum: Double = 0
        
        for dive in dives {
            sum += (dive.avgScore * (getDiveDD(data: diveTableData ?? [:],
                                               forKey: dive.number,
                                               height: dive.height) ?? 0.0) *
                    invertedNumberOfTimes(num: dive.numberOfTimes))
        }
        
        return sum
    }
    
    // Returns a triple of springboard rating, platform rating, and total rating
//    private func getSkillRating(link: String,
//                        metric: ([DiveStatistic]) -> Double) async -> (Double, Double, Double) {
//        let p = ProfileParser()
//        
//        let _ = await p.parseProfile(link: link)
//        guard let stats = p.profileData.diveStatistics else {
//            print("Failed getting stats")
//            return (0.0, 0.0, 0.0)
//        }
//        
//        return await getSkillRating(stats: stats, metric: metric)
//    }
    
    // Returns a triple of springboard rating, platform rating, and total rating
    func getSkillRating(diveMeetsID: String,
                        metric: ([DiveStatistic]) -> Double) async -> (Double, Double, Double) {
        let p = ProfileParser()
        
        let _ = await p.parseProfile(diveMeetsID: diveMeetsID)
        guard let stats = p.profileData.diveStatistics else {
            print("Failed getting stats")
            return (0.0, 0.0, 0.0)
        }
        
        return await getSkillRating(stats: stats, metric: metric)
    }
    
    // Returns a triple of springboard rating, platform rating, and total rating using the default
    // computeMetric1 function
    // Note: This recomputes the diver statistics each time since this theoretically would be called
    // after an update from a meet
    func getSkillRating(diveMeetsID: String) async -> (Double?, Double?, Double?) {
        let p = ProfileParser()
        
        let _ = await p.parseProfile(diveMeetsID: diveMeetsID)
        guard let stats = p.profileData.diveStatistics else {
            print("Failed getting stats")
            return (nil, nil, nil)
        }
        
        return await getSkillRating(stats: stats, metric: computeMetric1)
    }
    
    private func getSkillRating(stats: ProfileDiveStatisticsData,
                        metric: ([DiveStatistic]) -> Double) async -> (Double, Double, Double) {
        let skill = SkillRating(diveStatistics: stats)
        let divesByEvent = skill.getDiverStatsByEvent()
        
        let divesList = [("1M", divesByEvent.0), ("3M", divesByEvent.1), ("Platform", divesByEvent.2)]
        
        var springboard: Double = 0.0
        var platform: Double = 0.0
        for (event, dives) in divesList {
            let topDives = skill.getTopDives(dives: dives)
            let eventRating = metric(topDives)
            if event == "Platform" {
                platform += eventRating
            } else {
                springboard += eventRating
            }
        }
        
        return (springboard, platform, springboard + platform)
    }
    
    func getRatingNorm(value: Double, ratings: [Double]) -> Double {
        guard let min = ratings.min() else { return 0.0 }
        guard let max = ratings.max() else { return 0.0 }
        return (value - min) / (max - min) * 100.0
    }
    
    func normalizeRatings(ratings: [Double]) -> [Double] {
        var result: [Double] = []
        guard let min = ratings.min() else { return [] }
        guard let max = ratings.max() else { return [] }
        
        for value in ratings {
            if max - min == 0.0 {
                result.append(0.0)
            } else {
                result.append((value - min) / (max - min) * 100.0)
            }
        }
        
        return result
    }
    
    func testMetrics(_ index: Int, includePlatform: Bool = true, onlyPlatform: Bool = false) async {
        let metrics: [([DiveStatistic]) -> Double] = [computeMetric1]
        
        let pairs: [(String, String)] = [
            ("Tyler Downs", "36256"),
            ("Logan", "56961"),
            ("Holden", "45186"),
            ("Spencer", "51197"),
            ("Andrew", "36825"),
            ("Tim", "50923"),
            ("Skylar", "53397"),
            ("Trevor", "63091"),
            ("David Boudia", "11408"),
            ("Josh Parquet", "37447"),
            ("Dylan Reed", "43209"),
        ]
        
        var ratings: [Double] = []
        for (name, diveMeetsID) in pairs {
            let (springboard, platform, total) = await getSkillRating(diveMeetsID: diveMeetsID,
                                                                      metric: metrics[index])
            let rating: Double
            if onlyPlatform {
                rating = platform
            } else if includePlatform {
                rating = total
            } else {
                rating = springboard
            }
            
            ratings.append(rating)
            print(String(format: "\(name) Skill Rating: %.2f", rating))
            print("-------------------------")
        }
        
        print("-------------------------")
        
        var norms: [(String, Double)] = []
        for (i, (name, _)) in pairs.enumerated() {
            norms.append((name, getRatingNorm(value: ratings[i], ratings: ratings)))
        }
        
        for (name, rating) in norms.sorted(by: { $0.1 > $1.1 }) {
            print(String(format: "\(name) Skill Rating: %.2f", rating))
        }
    }
}
