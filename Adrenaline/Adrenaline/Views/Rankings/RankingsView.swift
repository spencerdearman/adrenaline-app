//
//  RankingsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/24/23.
//

import SwiftUI
import Amplify

enum BoardSelection: String, CaseIterable {
    case springboard = "Springboard"
    case combined = "Combined"
    case platform = "Platform"
}

enum RankingType: String, CaseIterable {
    case springboard = "Springboard"
    case combined = "Combined"
    case platform = "Platform"
}

enum GenderInt: Int, CaseIterable {
    case male = 0
    case female = 1
}

//                            [(NewAthlete, springboard, platform, total)]]
typealias GenderRankingList = [(NewAthlete, Double, Double, Double)]
typealias RankingListItem = (NewAthlete, Double)
typealias RankingList = [RankingListItem]
typealias NumberedRankingList = [(Int, RankingListItem)]

struct RankingsView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.networkIsConnected) private var networkIsConnected
    @State private var rankingType: RankingType = .combined
    @State private var gender: Gender = .male
    @State private var maleRatings: GenderRankingList = []
    @State private var femaleRatings: GenderRankingList = []
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @State private var selection: BoardSelection = .springboard
    @Binding var diveMeetsID: String
    @Binding var tabBarState: Visibility
    @Binding var showAccount: Bool
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    @ScaledMetric private var typeBubbleWidthScaled: CGFloat = 110
    @ScaledMetric private var typeBubbleHeightScaled: CGFloat = 35
    @ScaledMetric private var typeBGWidthScaled: CGFloat = 40
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var typeBubbleWidth: CGFloat {
        min(typeBubbleWidthScaled, 150)
    }
    private var typeBubbleHeight: CGFloat {
        min(typeBubbleHeightScaled, 48)
    }
    private var typeBGWidth: CGFloat {
        min(typeBGWidthScaled, 55)
    }
    
    private var typeBubbleColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    private let skill = SkillRating()
    
    private func getMaleAthletes() async -> [NewAthlete] {
        let pred = NewAthlete.keys.gender == "M"
        return await queryAWSAthletes(where: pred)
    }
    
    private func getFemaleAthletes() async -> [NewAthlete] {
        let pred = NewAthlete.keys.gender == "F"
        return await queryAWSAthletes(where: pred)
    }
    
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
    
    private func updateDiveMeetsDivers() async {
        if let url = Bundle.main.url(forResource: "rankedDiveMeetsIds", withExtension: "csv") {
            do {
                let content = try String(contentsOf: url)
                let parsedCSV: [String] = content.components(separatedBy: "\n")
                let p = ProfileParser()
                
                for id in parsedCSV {
                    print(id)
                    let _ = await p.parseProfile(diveMeetsID: id)
                    guard let info = p.profileData.info else { continue }
                    
                    guard let stats = p.profileData.diveStatistics else { continue }
                    let skillRating = SkillRating(diveStatistics: stats)
                    let (springboard, platform, total) = await skillRating.getSkillRating()
                    //                            print(springboard, platform, total)
                    
                    let obj = DiveMeetsDiver(id: id, firstName: info.first,
                                             lastName: info.last, finaAge: info.finaAge,
                                             hsGradYear: info.hsGradYear,
                                             springboardRating: springboard,
                                             platformRating: platform, totalRating: total)
//                    print(obj)
                    let _ = try await saveToDataStore(object: obj)
                    print("\(id) succeeded")
                }
            } catch {
                print("Failed to load rankedDiveMeetsIds")
            }
        }
    }
    
    private func deleteDiveMeetsDivers() async {
        if let url = Bundle.main.url(forResource: "rankedDiveMeetsIds", withExtension: "csv") {
            do {
                let content = try String(contentsOf: url)
                let parsedCSV: [String] = content.components(separatedBy: "\n")
                
                for id in parsedCSV {
                    print(id)
                    //                    print(obj)
                    let _ = try await Amplify.DataStore.delete(DiveMeetsDiver.self, where: DiveMeetsDiver.keys.id == id)
                    print("\(id) succeeded")
                }
            } catch {
                print("Failed to load rankedDiveMeetsIds")
            }
        }
    }
    
    var body: some View {
        ZStack {
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "RankingsBackground-Light" : "RankingsBackground-Dark")
                .frame(height: screenHeight * 0.8)
                .offset(x: -screenWidth * 0.1, y: screenHeight * 0.05)
            if networkIsConnected {
                ScrollView {
                    scrollDetection
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: screenHeight * 0.08)
                    
                    boardSelector
                    
                    RankingListView(tabBarState: $tabBarState, rankingType: $rankingType, 
                                    gender: $gender, maleRatings: $maleRatings,
                                    femaleRatings: $femaleRatings)
                    
                    Spacer()
                }
                .onAppear {
                    Task {
                        let males = await getMaleAthletes()
                        maleRatings = []
                        for male in males {
                            if let diveMeetsID = male.user.diveMeetsID, diveMeetsID != "", 
                                let springboard = male.springboardRating,
                                let platform = male.platformRating,
                                let total = male.totalRating {
                                maleRatings.append((male, springboard, platform, total))
                            }
                        }
                        
                        maleRatings = normalizeRatings(ratings: maleRatings)
                        
                        let females = await getFemaleAthletes()
                        femaleRatings = []
                        for female in females {
                            if let diveMeetsID = female.user.diveMeetsID, diveMeetsID != "",
                               let springboard = female.springboardRating,
                               let platform = female.platformRating,
                               let total = female.totalRating {
                                femaleRatings.append((female, springboard, platform, total))
                            }
                        }
                        
                        femaleRatings = normalizeRatings(ratings: femaleRatings)
                    }
                }
            } else {
                NotConnectedView()
            }
        }
        .overlay (
            NavigationBar(title: "Rankings",
                          diveMeetsID: $diveMeetsID,
                          showAccount: $showAccount,
                          contentHasScrolled: $contentHasScrolled,
                          feedModel: $feedModel)
            .frame(width: screenWidth)
        )
//        .onAppear {
//            Task {
////                await updateDiveMeetsDivers()
//                await deleteDiveMeetsDivers()
//            }
//        }
    }
    
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .onPreferenceChange(ScrollPreferenceKey.self) { offset in
            withAnimation(.easeInOut) {
                if offset < 0 {
                    contentHasScrolled = true
                } else {
                    contentHasScrolled = false
                }
            }
        }
    }
    
    var boardSelector: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .cornerRadius(30)
                    .frame(width: typeBubbleWidth * 3 + 5,
                           height: typeBGWidth)
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: typeBubbleWidth,
                           height: typeBubbleHeight)
                    .foregroundColor(Custom.darkGray.opacity(0.9))
                    .offset(x: rankingType == .springboard
                            ? -typeBubbleWidth / 1
                            : (rankingType == .combined ? 0 : typeBubbleWidth))
                    .animation(.spring(response: 0.2), value: rankingType)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.primary.opacity(0.5), lineWidth: 1) 
                            .offset(x: rankingType == .springboard
                                    ? -typeBubbleWidth / 1
                                    : (rankingType == .combined ? 0 : typeBubbleWidth))// Adjust the lineWidth as needed
                            .animation(.spring(response: 0.2), value: rankingType)
                    )
                HStack(spacing: 0) {
                    Button(action: {
                        rankingType = .springboard
                    }, label: {
                        Text(BoardSelection.springboard.rawValue)
                            .animation(nil, value: rankingType)
                    })
                    .frame(width: typeBubbleWidth,
                           height: typeBubbleHeight)
                    .cornerRadius(30)
                    Button(action: {
                        rankingType = .combined
                    }, label: {
                        Text(BoardSelection.combined.rawValue)
                            .animation(nil, value: rankingType)
                    })
                    .frame(width: typeBubbleWidth + 2,
                           height: typeBubbleHeight)
                    .cornerRadius(30)
                    Button(action: {
                        rankingType = .platform
                    }, label: {
                        Text(BoardSelection.platform.rawValue)
                            .animation(nil, value: rankingType)
                    })
                    .frame(width: typeBubbleWidth + 2,
                           height: typeBubbleHeight)
                    .cornerRadius(30)
                }
                .foregroundColor(.primary)
            }
            
            Button {
                withAnimation(.closeCard) {
                    if gender == .male {
                        gender = .female
                    } else {
                        gender = .male
                    }
                }
            } label: {
                Text(gender.rawValue)
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.secondary)
                    .background(gender == .male ? Color.blue.opacity(0.3) : Color.pink.opacity(0.3))
                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
            }
        }
    }
}

struct RankingListView: View {
    @Environment(\.colorScheme) private var currentMode
    @Binding var tabBarState: Visibility
    @Binding var rankingType: RankingType
    @Binding var gender: Gender
    @Binding var maleRatings: GenderRankingList
    @Binding var femaleRatings: GenderRankingList
    
    private let screenWidth = UIScreen.main.bounds.width
    
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
            else if $0.1 == $1.1 {
                // If they share matching values, sort by first name
                return $0.0.user.firstName < $1.0.user.firstName
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
        VStack {
            // Column headers
            ZStack {
                Rectangle()
                    .frame(width: screenWidth * 0.9, height: screenWidth * 0.1)
                    .foregroundColor(Custom.darkGray)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 5)
                
                HStack {
                    Text("Rank")
                        .padding(.leading, 17)
                        .padding(.trailing, 20)
                    Text("Name")
                    Spacer()
                    Text("Rating")
                        .padding(.trailing, 31)
                }
                .bold()
                .padding()
            }
            
            HideTabBarScrollView(tabBarState: $tabBarState) {
                VStack {
                    ForEach(numberedList.indices, id: \.self) { index in
                        let number = numberedList[index].0
                        let athlete = numberedList[index].1.0
                        let rating = numberedList[index].1.1
                        
                        RankingListDiverView(number: number, athlete: athlete, rating: rating)
                    }
                }
                .padding()
            }
        }
    }
}

struct RankingListDiverView: View {
    @Environment(\.colorScheme) private var currentMode
    var number: Int
    var athlete: NewAthlete
    var rating: Double
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: screenWidth * 0.9)
                .foregroundColor(Custom.darkGray)
                .mask(RoundedRectangle(cornerRadius: 40))
                .shadow(radius: 5)
            HStack {
                Text(String(number))
                    .padding(.leading)
                    .padding(.trailing, 40)
                // TODO: link row to profile
                Text((athlete.user.firstName) + " "  + (athlete.user.lastName))
                    .foregroundColor(.primary)
                
                Spacer()
                Text(String(format: "%.1f", rating))
                    .padding(.trailing)
            }
            .padding()
        }
    }
}
