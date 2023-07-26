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
        
        for i in 0..<ratings.count {
            result.append((ratings[i].0, springboard[i], platform[i], total[i]))
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
    
    private func getSortedRankingList() -> [(Athlete, Double)] {
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
    
    var body: some View {
        let sortedList = getSortedRankingList()
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(sortedList.indices, id: \.self) { index in
                    let athlete = sortedList[index].0
                    let rating = sortedList[index].1
                    BackgroundBubble() {
                        HStack {
                            Text(String(index + 1))
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
