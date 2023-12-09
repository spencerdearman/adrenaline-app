//
//  RankingsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/24/23.
//

import SwiftUI
import Amplify

// Cache RankingList to avoid slow sorting
//                 [Gender: [AgeGrp: [Board : NumberedRankingList]]]
var cachedRatings: [String: [String: [String: NumberedRankingList]]] = [:]

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

enum AgeGroup: String, CaseIterable {
    case fourteenFifteen = "14-15"
    case sixteenEighteen = "16-18"
}

struct RankedUser {
    var firstName: String
    var lastName: String
    var diveMeetsID: String
    var gender: String
    var finaAge: Int?
    var hsGradYear: Int?
    var springboardRating: Double
    var platformRating: Double
    var totalRating: Double
}

//                            [(User      , sb    , plat  , tot)]
typealias GenderRankingList = [(RankedUser, Double, Double, Double)]
typealias RankingListItem = (RankedUser, Double)
typealias RankingList = [RankingListItem]
typealias NumberedRankingList = [(Int, RankingListItem)]

struct RankingsView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.networkIsConnected) private var networkIsConnected
    @State private var rankingType: RankingType = .combined
    @State private var gender: Gender = .male
    @State private var ageGroup: AgeGroup = .fourteenFifteen
    @State private var maleRatings: GenderRankingList = []
    @State private var femaleRatings: GenderRankingList = []
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @State private var selection: BoardSelection = .springboard
    @State private var isAdrenalineProfilesOnlyChecked: Bool = false
    @Binding var newUser: NewUser?
    @Binding var tabBarState: Visibility
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
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
    
    private func getMaleAthletes() async -> [NewAthlete] {
        let pred = NewAthlete.keys.gender == "M"
        return await queryAWSAthletes(where: pred)
    }
    
    private func getMaleDiveMeetsDivers() async throws -> [(RankedUser, Double, Double, Double)] {
        var result: [(RankedUser, Double, Double, Double)] = []
        let pred = DiveMeetsDiver.keys.gender == "M"
        let divers: [DiveMeetsDiver] = try await query(where: pred)
        for diver in divers {
            if let springboard = diver.springboardRating,
               let platform = diver.platformRating,
               let total = diver.totalRating {
                result.append((RankedUser(firstName: diver.firstName, lastName: diver.lastName,
                                          diveMeetsID: diver.id, gender: diver.gender,
                                          finaAge: diver.finaAge, hsGradYear: diver.hsGradYear,
                                          springboardRating: springboard, platformRating: platform,
                                          totalRating: total), springboard, platform, total))
            }
        }
        
        return result
    }
    
    private func getFemaleAthletes() async -> [NewAthlete] {
        let pred = NewAthlete.keys.gender == "F"
        return await queryAWSAthletes(where: pred)
    }
    
    private func getFemaleDiveMeetsDivers() async throws -> [(RankedUser, Double, Double, Double)] {
        var result: [(RankedUser, Double, Double, Double)] = []
        let pred = DiveMeetsDiver.keys.gender == "F"
        let divers: [DiveMeetsDiver] = try await query(where: pred)
        for diver in divers {
            if let springboard = diver.springboardRating,
               let platform = diver.platformRating,
               let total = diver.totalRating {
                result.append((RankedUser(firstName: diver.firstName, lastName: diver.lastName,
                                          diveMeetsID: diver.id, gender: diver.gender,
                                          finaAge: diver.finaAge, hsGradYear: diver.hsGradYear,
                                          springboardRating: springboard, platformRating: platform,
                                          totalRating: total), springboard, platform, total))
            }
        }
        
        return result
    }
    
    // Keeps first seen of each diveMeetsID for each list in case there are
    // duplicates between registered Adrenaline athletes and DiveMeetsDivers
    // Note: all DiveMeetsDiver objects are added after Adrenaline users, so this should keep the
    //       desired user in the list (the Adrenaline user)
    private func removeDuplicates(_ ratings: GenderRankingList) ->
    [(RankedUser, Double, Double, Double)] {
        var seen = Set<String>()
        var result: [(RankedUser, Double, Double, Double)] = []
        
        for elem in ratings {
            if !seen.contains(elem.0.diveMeetsID) {
                result.append(elem)
                seen.insert(elem.0.diveMeetsID)
            }
        }
        
        return result
    }
    
    private func getMaleRatings() async throws {
        // Get all male Athlete profiles from the DataStore
        let males = await getMaleAthletes()
        maleRatings = []
        var pendingMaleRatings: GenderRankingList = []
        for male in males {
            if let diveMeetsID = male.user.diveMeetsID, diveMeetsID != "",
               let springboard = male.springboardRating,
               let platform = male.platformRating,
               let total = male.totalRating {
                let rankedUser = RankedUser(firstName: male.user.firstName,
                                            lastName: male.user.lastName,
                                            diveMeetsID: diveMeetsID,
                                            gender: male.gender,
                                            finaAge: male.age,
                                            hsGradYear: male.graduationYear,
                                            springboardRating: springboard,
                                            platformRating: platform,
                                            totalRating: total)
                pendingMaleRatings.append((rankedUser, springboard, platform,
                                           total))
            }
        }
        
        // Add in DiveMeetsDiver users
        pendingMaleRatings += try await getMaleDiveMeetsDivers()
        
        // Remove duplicate entries and normalize
        maleRatings = removeDuplicates(pendingMaleRatings)
    }
    
    private func getFemaleRatings() async throws {
        // Get all female Athlete profiles from the DataStore
        let females = await getFemaleAthletes()
        femaleRatings = []
        var pendingFemaleRatings: GenderRankingList = []
        for female in females {
            if let diveMeetsID = female.user.diveMeetsID, diveMeetsID != "",
               let springboard = female.springboardRating,
               let platform = female.platformRating,
               let total = female.totalRating {
                let rankedUser = RankedUser(firstName: female.user.firstName,
                                            lastName: female.user.lastName,
                                            diveMeetsID: diveMeetsID,
                                            gender: female.gender,
                                            finaAge: female.age,
                                            hsGradYear: female.graduationYear,
                                            springboardRating: springboard,
                                            platformRating: platform,
                                            totalRating: total)
                pendingFemaleRatings.append((rankedUser, springboard, platform,
                                             total))
            }
        }
        
        // Add in DiveMeetsDiver users
        pendingFemaleRatings += try await getFemaleDiveMeetsDivers()
        
        // Remove duplicate entries and normalize
        femaleRatings = removeDuplicates(pendingFemaleRatings)
    }
    
    var body: some View {
        NavigationView {
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
                        
                        HStack {
                            Text("Only show Adrenaline profiles")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isAdrenalineProfilesOnlyChecked.toggle()
                                }
                            } label: {
                                Image(systemName: "checkmark.shield")
                                    .opacity(isAdrenalineProfilesOnlyChecked ? 1.0 : 0.0)
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.secondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Custom.medBlue, lineWidth: 1.5)
                                    )
                                    .background(isAdrenalineProfilesOnlyChecked
                                                ? Color.blue.opacity(0.3)
                                                : Color.clear)
                                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                                    .scaleEffect(0.8)
                            }
                            
                            Spacer()
                        }
                        .padding(.leading)
                        
                        boardSelector
                        
                        if (gender == .male && !maleRatings.isEmpty) ||
                            (gender == .female && !femaleRatings.isEmpty) {
                            RankingListView(tabBarState: $tabBarState,
                                            adrenalineProfilesOnly: $isAdrenalineProfilesOnlyChecked,
                                            rankingType: $rankingType,
                                            gender: $gender, ageGroup: $ageGroup,
                                            maleRatings: $maleRatings,
                                            femaleRatings: $femaleRatings)
                            
                            Spacer()
                        } else {
                            ProgressView()
                        }
                    }
                    .onAppear {
                        Task {
                            if maleRatings.isEmpty {
                                try await getMaleRatings()
                            }
                            
                            if femaleRatings.isEmpty {
                                try await getFemaleRatings()
                            }
                        }
                    }
                } else {
                    NotConnectedView()
                }
            }
            .overlay (
                NavigationBar(title: "Rankings",
                              newUser: $newUser,
                              showAccount: $showAccount,
                              contentHasScrolled: $contentHasScrolled,
                              feedModel: $feedModel, recentSearches: $recentSearches,
                              uploadingPost: $uploadingPost)
                .frame(width: screenWidth)
            )
        }
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
                                    : (rankingType == .combined ? 0 : typeBubbleWidth))
                        // Adjust the lineWidth as needed
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
            
            Menu {
                Picker("", selection: $ageGroup) {
                    ForEach(AgeGroup.allCases, id: \.self) { g in
                        Text(g.rawValue)
                            .tag(g)
                    }
                }
            } label: { Text("Age") }
        }
    }
}

struct RankingListView: View {
    @Environment(\.colorScheme) private var currentMode
    @Binding var tabBarState: Visibility
    @Binding var adrenalineProfilesOnly: Bool
    @Binding var rankingType: RankingType
    @Binding var gender: Gender
    @Binding var ageGroup: AgeGroup
    @Binding var maleRatings: GenderRankingList
    @Binding var femaleRatings: GenderRankingList
    
    private let skill = SkillRating()
    private let screenWidth = UIScreen.main.bounds.width
    
    private func isInAgeRange(age: Int) -> Bool {
        switch ageGroup {
            case .fourteenFifteen:
                return 14 <= age && age <= 15
            case .sixteenEighteen:
                return 16 <= age && age <= 18
        }
    }
    
    private func filterByAgeGroup(_ ratings: GenderRankingList) -> GenderRankingList {
        var result: GenderRankingList = []
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let currentDate: Date = .now
        let boundaryYear: Int
        
        // If in or after June, set boundary at the following year
        // e.g. if Nov 2023, set year to 2024
        if Calendar.current.component(.month, from: currentDate) >= 6 {
            boundaryYear = Calendar.current.component(.year, from: currentDate) + 1
        } else {
            boundaryYear = Calendar.current.component(.year, from: currentDate)
        }
        
        var lowerBoundYear = boundaryYear
        if ageGroup == .fourteenFifteen {
            lowerBoundYear += 3
        }
        
        // Sets gradYear range for age group
        // e.g. 14-15 age group -> 2027-2028, 16-18 age group -> 2024-2026
        let upperBoundYear = ageGroup == .fourteenFifteen ? lowerBoundYear + 1 : lowerBoundYear + 2
        
        for rating in ratings {
            let user = rating.0
            
            // If age exists and in age range, append and continue
            if let age = user.finaAge, isInAgeRange(age: age) {
                result.append(rating)
                continue
            }
            
            // If age doesn't exist or it is not in range, but gradYear is, append
            if let gradYear = user.hsGradYear,
               gradYear >= lowerBoundYear, gradYear <= upperBoundYear {
                result.append(rating)
            }
        }
        
        return result
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
    
    private func ratingListInCache(gender: Gender, ageGroup: AgeGroup,
                                   board: RankingType) -> NumberedRankingList? {
        if let genderDict = cachedRatings[gender.rawValue],
           let ageGroupDict = genderDict[ageGroup.rawValue],
           let boardList = ageGroupDict[board.rawValue] {
            return boardList
        }
        
        return nil
    }
    
    private func cacheRatingList(gender: Gender, ageGroup: AgeGroup, board: RankingType,
                                 ratings: NumberedRankingList) {
        if !cachedRatings.keys.contains(gender.rawValue) {
            cachedRatings[gender.rawValue] = [:]
        }
        
        if !cachedRatings[gender.rawValue]!.keys.contains(ageGroup.rawValue) {
            cachedRatings[gender.rawValue]![ageGroup.rawValue] = [:]
        }
        
        cachedRatings[gender.rawValue]![ageGroup.rawValue]![board.rawValue] = ratings
    }
    
    private func getSortedRankingList() -> RankingList {
        let list = gender == .male ? maleRatings : femaleRatings
        let filtered = filterByAgeGroup(list)
        let normalized = normalizeRatings(ratings: filtered)
        let keep = normalized.map {
            // Values rounded to one decimal place
            switch rankingType {
                case .springboard:
                    return ($0.0, round($0.1 * 10) / 10.0)
                case .combined:
                    return ($0.0, round($0.3 * 10) / 10.0)
                case .platform:
                    return ($0.0, round($0.2 * 10) / 10.0)
            }
        }
        
        // Sorts by decreasing rating and filters out ratings below 1.0
        return keep.sorted(by: {
            if $0.1 > $1.1 { return true }
            else if $0.1 == $1.1 {
                // If they share matching values, sort by first name
                return $0.0.firstName < $1.0.firstName
            } else {
                return false
            }
        }).filter { $0.1 >= 1.0 }
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
                    print(rating, item)
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
            print("\(error)")
            print("Failed to number list, items not sorted in descending order")
            return []
        }
        
        // Caches rating list for future viewing since it won't change
        cacheRatingList(gender: gender, ageGroup: ageGroup, board: rankingType, ratings: result)
        
        return result
    }
    
    private func getFinalRankingList() -> NumberedRankingList {
        if let result = ratingListInCache(gender: gender, ageGroup: ageGroup, board: rankingType) {
            return result
        }
        
        return numberSortedRankingList(getSortedRankingList())
    }
    
    var body: some View {
        let numberedList = getFinalRankingList()
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
                LazyVStack {
                    ForEach(numberedList.indices, id: \.self) { index in
                        let number = numberedList[index].0
                        let rankedUser = numberedList[index].1.0
                        let rating = numberedList[index].1.1
                        
                        RankingListDiverView(number: number, rankedUser: rankedUser, rating: rating,
                                             adrenalineProfilesOnly: $adrenalineProfilesOnly)
                    }
                    
                    Text("Ratings below 1.0 are not displayed")
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
        }
    }
}

struct RankingListDiverView: View {
    @Environment(\.colorScheme) private var currentMode
    @State private var newUser: NewUser? = nil
    var number: Int
    var rankedUser: RankedUser
    var rating: Double
    @Binding var adrenalineProfilesOnly: Bool
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var userName: some View {
        Text((rankedUser.firstName) + " "  + (rankedUser.lastName))
    }
    
    var body: some View {
        ZStack {
            if !adrenalineProfilesOnly || newUser != nil {
                Rectangle()
                    .frame(width: screenWidth * 0.9)
                    .foregroundColor(Custom.darkGray)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 5)
                HStack {
                    Text(String(number))
                        .padding(.leading)
                        .padding(.trailing, 40)
                    
                    if let diver = newUser {
                        NavigationLink(destination: AdrenalineProfileView(newUser: diver)) {
                            userName
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        userName
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    Text(String(format: "%.1f", rating))
                        .padding(.trailing)
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                if newUser == nil {
                    let pred = NewUser.keys.diveMeetsID == rankedUser.diveMeetsID
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        newUser = users[0]
                    }
                }
            }
        }
    }
}
