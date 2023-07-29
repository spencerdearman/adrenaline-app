//
//  RankingsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/24/23.
//

import SwiftUI

enum RankingType: String, CaseIterable {
    case springboard = "Springboard"
    case combined = "Combined"
    case platform = "Platform"
}

enum GenderInt: Int, CaseIterable {
    case male = 0
    case female = 1
}

//                            [(Athlete, springboard, platform, total)]]
typealias GenderRankingList = [(Athlete, Double, Double, Double)]
typealias RankingListItem = (Athlete, Double)
typealias RankingList = [RankingListItem]
typealias NumberedRankingList = [(Int, RankingListItem)]

struct RankingsView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.getMaleAthletes) var getMaleAthletes
    @Environment(\.getFemaleAthletes) var getFemaleAthletes
    @State private var rankingType: RankingType = .combined
    @State private var gender: Gender = .male
    @State private var maleRatings: GenderRankingList = []
    @State private var femaleRatings: GenderRankingList = []
    
    private let skill = SkillRating(diveStatistics: nil)
    
    private func normalizeRatings(ratings: GenderRankingList) -> GenderRankingList {
        var result: GenderRankingList = []
        var springboard: [Double] = []
        var platform: [Double] = []
        var total: [Double] = []
        
        for (_, spring, plat, tot) in ratings {
            springboard.append(spring)
            platform.append(plat)
            total.append(tot)
        }
        
        springboard = skill.normalizeRatings(ratings: springboard)
        platform = skill.normalizeRatings(ratings: platform)
        total = skill.normalizeRatings(ratings: total)
        
        // Don't include only one user, since ratings don't make sense
        if ratings.count > 1 {
            for i in 0..<ratings.count {
                result.append((ratings[i].0, springboard[i], platform[i], total[i]))
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack {
            Text("Rankings")
                .font(.title)
                .bold()
            
            BubbleSelectView(selection: $rankingType)
                .padding([.leading, .trailing])
            
            BubbleSelectView(selection: $gender)
                .padding([.leading, .trailing])
            
            Divider()
            
            RankingListView(rankingType: $rankingType, gender: $gender,
                            maleRatings: $maleRatings, femaleRatings: $femaleRatings)
            
            Spacer()
        }
        .onAppear {
            if let males = getMaleAthletes() {
                maleRatings = []
                for male in males {
                    maleRatings.append((male, male.springboardRating,
                                        male.platformRating,
                                        male.totalRating))
                }
                
                maleRatings = normalizeRatings(ratings: maleRatings)
            }
            
            if let females = getFemaleAthletes() {
                femaleRatings = []
                for female in females {
                    femaleRatings.append((female, female.springboardRating,
                                        female.platformRating,
                                        female.totalRating))
                }
                
                femaleRatings = normalizeRatings(ratings: femaleRatings)
            }
        }
    }
}

struct RankingListView: View {
    @Binding var rankingType: RankingType
    @Binding var gender: Gender
    @Binding var maleRatings: GenderRankingList
    @Binding var femaleRatings: GenderRankingList
    
    private func getSortedRankingList() -> RankingList {
        let list = gender == .male ? maleRatings : femaleRatings
        let keep = list.map {
            switch rankingType {
                case .springboard:
                    return ($0.0, $0.1)
                case .combined:
                    return ($0.0, $0.3)
                case .platform:
                    return ($0.0, $0.2)
            }
        }
        
        return keep.sorted(by: {
            if $0.1 > $1.1 { return true }
            else if $0.1 == $1.1,
                        let oneLast = $0.0.lastName,
                    let twoLast = $1.0.lastName,
                    oneLast < twoLast {
                return true
            } else {
                return false
            }
        })
    }
    
    // This should be called after sorting to get a number for that result in the ranking list view
    private func numberSortedRankingList(_ list: RankingList) -> NumberedRankingList {
        var result: NumberedRankingList = []
        
        var everyIdx: Int = 0
        var curIdx: Int = 0
        var curRating: Double = 100.1
        
        do {
            for item in list {
                let rating = item.1
                
                // Fails fast if unsorted list is passed in (ratings should be in descending order)
                if rating > curRating {
                    throw ParseError("Numbering ranking list failed")
                }

                // If the rating is strictly less than the previous, then it updates the assigned
                // number to the next number of the items it has seen (this keeps track of the
                // total number of items seen so when there are ties, the next stricly lower rating
                // will be appropriately ranked)
                if rating < curRating {
                    curRating = rating
                    curIdx = everyIdx + 1
                }
                // If the rating is equal to the previous, the current rating need not be updated
                // and the current index stays the same (this creates multiple of the same ranking
                // number for ratings that are equal)

                result.append((curIdx, item))
                
                everyIdx += 1
            }
        } catch {
            print("Failed to number list, items not sorted in descending order")
            return []
        }
        
        return result
    }
    
    var body: some View {
        let numberedList = numberSortedRankingList(getSortedRankingList())
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(numberedList.indices, id: \.self) { index in
                    let number = numberedList[index].0
                    let athlete = numberedList[index].1.0
                    let rating = numberedList[index].1.1
                    BackgroundBubble() {
                        HStack {
                            Text(String(number))
                                .padding(.trailing)
                            Text((athlete.firstName ?? "") + " "  +
                                 (athlete.lastName ?? ""))
                            Spacer()
                            Text(String(format: "%.1f", rating))
                        }
                        .padding([.leading, .trailing])
                    }
                    .padding([.leading, .trailing])
                }
            }
            .padding()
        }
    }
}

struct RankingsView_Previews: PreviewProvider {
    static var previews: some View {
        RankingsView()
    }
}
