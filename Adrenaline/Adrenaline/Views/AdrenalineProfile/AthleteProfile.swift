//
//  AthleteProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI
import Amplify
import Combine

struct DiverView: View {
    var newUser: NewUser
    @ScaledMetric private var linkButtonWidthScaled: CGFloat = 300
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    
    private var linkButtonWidth: CGFloat {
        min(linkButtonWidthScaled, screenWidth * 0.8)
    }
    
    var body: some View {
        VStack {
            ProfileContent(newUser: newUser)
                .padding(.top, screenHeight * 0.05)
            Spacer()
        }
    }
}

struct ProfileContent: View {
    @AppStorage("authUserId") private var authUserId: String = ""
    @State var scoreValues: [String] = []
    @State var selectedPage: Int = 0
    var newUser: NewUser
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenHeight = UIScreen.main.bounds.height
    private let baseScoreValues = ["Posts", "Results", "Recruiting"]
    
    var body: some View {
        SwiftUIWheelPicker($selectedPage, items: scoreValues) { value in
            GeometryReader { g in
                Text(value)
                    .dynamicTypeSize(.xSmall ... .xLarge)
                    .font(.title2).fontWeight(.semibold)
                    .frame(width: g.size.width, height: g.size.height,
                           alignment: .center)
            }
        }
        .scrollAlpha(0.3)
        .width(.Fixed(115))
        .scrollScale(0.7)
        .frame(height: 40)
        .onAppear {
            scoreValues = baseScoreValues
            
            // If viewing the user's own profile, show Saved and Favorites tab
            if newUser.id == authUserId {
                scoreValues += ["Saved", "Favorites"]
            }
        }
        
        Group {
            switch selectedPage {
                case 0:
                    AnyView(PostsView(newUser: newUser))
                case 1:
                    AnyView(MeetListView(newUser: newUser, nameShowing: false))
                case 2:
                    AnyView(RecruitingView(newUser: newUser))
                case 3:
                    AnyView(SavedPostsView(newUser: newUser))
                case 4:
                    AnyView(FavoritesView(newUser: newUser))
                default:
                    AnyView(MeetListView(newUser: newUser, nameShowing: false))
            }
        }
        .offset(y: -screenHeight * 0.05)
    }
}

struct MeetListView: View {
    var newUser: NewUser
    var nameShowing: Bool = true
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        if let diveMeetsID = newUser.diveMeetsID, diveMeetsID != "" {
            MeetList(
                profileLink: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                diveMeetsID, nameShowing: nameShowing)
        } else {
            Text("No DiveMeets Account Linked")
                .foregroundColor(.secondary)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
                .multilineTextAlignment(.center)
        }
    }
}

struct MetricsView: View {
    var diveMeetsID: String?
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if let diveMeetsID = diveMeetsID {
            SkillsGraph(
                profileLink: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                diveMeetsID)
        } else {
            BackgroundBubble() {
                Text("Unable to get metrics, account is not linked to DiveMeets")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(width: screenWidth * 0.9)
        }
    }
}

struct RecruitingDataView: View {
    @State private var currentUserIsCoach: Bool = false
    @AppStorage("authUserId") private var authUserId: String = ""
    var newUser: NewUser
    var newAthlete: NewAthlete
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            // If current user is a Coach profile, or if current user is viewing their own profile
            if currentUserIsCoach || authUserId == newUser.id {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 4)
                    HStack {
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: screenWidth * 0.07,
                                   height: screenWidth * 0.07)
                        Spacer()
                        Text("\(newUser.email)")
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .shadow(radius: 4)
                        HStack {
                            Image(systemName: "ruler.fill")
                                .resizable()
                                .rotationEffect(.degrees(90))
                                .aspectRatio(contentMode: .fit)
                                .frame(width: screenWidth * 0.07,
                                       height: screenWidth * 0.07)
                            
                            Spacer()
                            Text("\(newAthlete.heightFeet)' \(newAthlete.heightInches)\"")
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .shadow(radius: 4)
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: screenWidth * 0.07,
                                       height: screenWidth * 0.07)
                            Spacer()
                            Text("\(newAthlete.weight) \(newAthlete.weightUnit)")
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            
            HStack {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 4)
                    HStack {
                        Image(systemName: "snowflake")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: screenWidth * 0.07,
                                   height: screenWidth * 0.07)
                        Spacer()
                        Text("\(newAthlete.gender)")
                    }
                    .padding()
                }
                
                Spacer()
                
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 4)
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: screenWidth * 0.07,
                                   height: screenWidth * 0.07)
                        Spacer()
                        Text(verbatim: "\(newAthlete.graduationYear)")
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            if currentUserIsCoach {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 4)
                    HStack {
                        Image(systemName: "book.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: screenWidth * 0.07,
                                   height: screenWidth * 0.07)
                        Spacer()
                        Text("\(newAthlete.highSchool)")
                    }
                    .padding()
                }
                
                Spacer()
            }
            
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 4)
                
                HStack {
                    VStack {
                        Text("Springboard")
                        Text(String(format: "%.1f", newAthlete.springboardRating ?? 0.0))
                            .bold()
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack {
                        Text("Platform")
                        Text(String(format: "%.1f", newAthlete.platformRating ?? 0.0))
                            .bold()
                    }
                    .padding()
                    
                    Spacer()
                    
                    VStack {
                        Text("Total")
                        Text(String(format: "%.1f", newAthlete.totalRating ?? 0.0))
                            .bold()
                    }
                    .padding()
                }
                .padding([.leading, .trailing])
            }
        }
        .padding()
        .onAppear {
            Task {
                // Get currentUser and check accountType to determine what is displayed
                let pred = NewUser.keys.id == authUserId
                let users = await queryAWSUsers(where: pred)
                if users.count == 1, users[0].accountType == "Coach" {
                    currentUserIsCoach = true
                }
            }
        }
    }
}

struct RecruitingView: View {
    var newUser: NewUser
    @State var newAthlete: NewAthlete?
    @State var loaded: Bool = false
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ScrollView {
            VStack {
                // Gives view time to query AWS before showing anything (avoids glitching when top
                // portion appears after lower portion)
                if loaded {
                    // Always show DataView once it is loaded
                    if let athlete = newAthlete {
                        RecruitingDataView(newUser: newUser, newAthlete: athlete)
                        
                        Divider()
                    }
                    
                    // Only show metrics and stats if DiveMeets account is linked
                    if let diveMeetsID = newUser.diveMeetsID, diveMeetsID != "" {
                        MetricsView(diveMeetsID: diveMeetsID)
                        
                        Divider()
                        
                        StatisticsView(diveMeetsID: diveMeetsID)
                    } else {
                        Text("Link a DiveMeets account to display metrics and dive statistics on your profile")
                            .foregroundColor(.secondary)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()
                            .padding(.bottom, 30)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                newAthlete = try await newUser.athlete
                loaded = true
            }
        }
    }
}

struct StatisticsView: View {
    @Environment(\.colorScheme) private var currentMode
    @State var stats: ProfileDiveStatisticsData = []
    @State var filteredStats: ProfileDiveStatisticsData = []
    @State var categorySelection: Int = 0
    @State var heightSelection: Int = 0
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 240
    
    var diveMeetsID: String?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let parser: ProfileParser = ProfileParser()
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled * 0.95, 230)
    }
    
    private func getHeightString(_ height: Double) -> String {
        var heightString: String = ""
        if Double(Int(height)) == height {
            heightString = String(Int(height))
        } else {
            heightString = String(height)
        }
        
        return heightString + "M"
    }
    
    private func getCategoryString(_ category: Int) -> String {
        switch category {
            case 1:
                return "Forward"
            case 2:
                return "Back"
            case 3:
                return "Reverse"
            case 4:
                return "Inward"
            case 5:
                return "Twist"
            case 6:
                return "Armstand"
            default:
                return ""
        }
    }
    
    private func updateFilteredStats() {
        filteredStats = stats.filter {
            categorySelection == 0 || String(categorySelection) == $0.number.prefix(1)
        }.filter {
            heightSelection == 0 || heightSelection == Int($0.height) ||
            (heightSelection == 5 && $0.height >= 5)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Menu {
                    Picker("", selection: $categorySelection) {
                        ForEach([0, 1, 2, 3, 4, 5, 6], id: \.self) { elem in
                            if elem == 0 {
                                Text(String("All"))
                                    .tag(elem)
                            } else {
                                HStack {
                                    Image(systemName: "\(elem).circle")
                                    Text(getCategoryString(elem))
                                }
                                .tag(elem)
                            }
                        }
                    }
                    Divider()
                    Picker("", selection: $heightSelection) {
                        ForEach([0, 1, 3, 5], id: \.self) { elem in
                            let text = elem == 0 ? "All" : (elem == 5 ? "Platform" : "\(elem)M")
                            Text(text)
                                .tag(elem)
                        }
                    }
                } label: {
                    Text("**Filter**")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.trailing, 20)
            
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(filteredStats, id: \.self) { stat in
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .mask(RoundedRectangle(cornerRadius: 40))
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading) {
                                Text(stat.number + " - " + stat.name)
                                    .bold()
                                    .lineLimit(2)
                                Text(getHeightString(stat.height))
                                    .bold()
                                    .font(.headline)
                                    .foregroundColor(Custom.secondaryColor)
                                Text("Average Score: " + String(stat.avgScore))
                                Text("High Score: " + String(stat.highScore))
                                Text("Number of Times: " + String(stat.numberOfTimes))
                            }
                            .padding()
                        }
                        .frame(width: screenWidth * 0.9)
                        .padding([.leading, .trailing])
                    }
                }
                .padding(.top)
                .padding(.bottom, maxHeightOffset)
            }
            .onChange(of: maxHeightOffsetScaled) {
                print(maxHeightOffset)
            }
            .onAppear {
                if stats.isEmpty, let diveMeetsID = diveMeetsID {
                    Task {
                        if !cachedStats.keys.contains(diveMeetsID) {
                            if await parser.parseProfile(diveMeetsID: diveMeetsID) {
                                
                                guard let parsedStats = parser.profileData.diveStatistics else { return }
                                cachedStats[diveMeetsID] = parsedStats
                            } else {
                                print("Failed to parse profile")
                            }
                        }
                        
                        if let cached = cachedStats[diveMeetsID] {
                            stats = cached
                            filteredStats = cached
                        }
                    }
                }
            }
        }
        .onChange(of: categorySelection) {
            updateFilteredStats()
        }
        .onChange(of: heightSelection) {
            updateFilteredStats()
        }
    }
}
