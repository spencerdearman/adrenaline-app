//
//  AthleteProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI
import Amplify

struct DiverView: View {
    var graphUser: GraphUser
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
            // Showing DiveMeets Linking Screen
            if (graphUser.diveMeetsID == nil || graphUser.diveMeetsID == "") {
                Spacer()
                NavigationLink(destination: {
                    DiveMeetsLink(graphUser: graphUser)
                }, label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Custom.darkGray)
                            .cornerRadius(50)
                            .shadow(radius: 10)
                        Text("Link DiveMeets Account")
                            .foregroundColor(.primary)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                    }
                    .frame(width: linkButtonWidth, height: screenHeight * 0.05)
                })
                Spacer()
                Spacer()
                Spacer()
            } else {
                ProfileContent(graphUser: graphUser)
                    .padding(.top, screenHeight * 0.05)
            }
            Spacer()
        }
    }
}

struct ProfileContent: View {
    @State var scoreValues: [String] = ["Posts", "Results", "Recruiting", "Saved"]
    @State var selectedPage: Int = 0
    @State var newUser: NewUser? = nil
    var graphUser: GraphUser
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenHeight = UIScreen.main.bounds.height
    
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
            if scoreValues.last != "Favorites" {
                scoreValues.append("Favorites")
            }
            
            Task {
                let predicate = NewUser.keys.email == graphUser.email
                let savedUsers = await queryAWSUsers(where: predicate)
                if savedUsers.count != 1 {
                    print("Invalid user count, returning...")
                    return
                }
                
                newUser = savedUsers[0]
            }
        }
        
        Group {
            switch selectedPage {
                case 0:
                    if let user = newUser {
                        AnyView(PostsView(newUser: user))
                    }
                case 1:
                    AnyView(MeetListView(diveMeetsID: graphUser.diveMeetsID, nameShowing: false))
                case 2:
                    if let user = newUser {
                        AnyView(RecruitingView(newUser: user))
                    }
                case 3:
                    AnyView(SavedPostsView())
                case 4:
                    if let user = newUser {
                        AnyView(FavoritesView(newUser: user))
                    }
                default:
                    if let newUser = newUser {
                        AnyView(MeetListView(diveMeetsID: newUser.diveMeetsID, nameShowing: false))
                    }
            }
        }
        .offset(y: -screenHeight * 0.05)
    }
}

struct MeetListView: View {
    var diveMeetsID: String?
    var nameShowing: Bool = true
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        if let diveMeetsID = diveMeetsID {
            MeetList(
                profileLink: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                diveMeetsID, nameShowing: nameShowing)
        } else {
            BackgroundBubble() {
                Text("Cannot get meet list data, account is not linked to DiveMeets")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(width: screenWidth * 0.9)
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
    var newAthlete: NewAthlete
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
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
    }
}

struct RecruitingView: View {
    var newUser: NewUser
    @State var newAthlete: NewAthlete?
    @State var loaded: Bool = false
    
    var body: some View {
        ScrollView {
            // Gives view time to query AWS before showing anything (avoids glitching when top
            // portion appears after lower portion)
            if loaded {
                VStack {
                    if let athlete = newAthlete {
                        RecruitingDataView(newAthlete: athlete)
                        
                        Divider()
                    }
                    
                    MetricsView(diveMeetsID: newUser.diveMeetsID)
                    
                    Divider()
                    
                    StatisticsView(diveMeetsID: newUser.diveMeetsID)
                }
                .padding()
                
            }
        }
        .onAppear {
            Task {
                let athletes = await queryAWSAthletes().filter { $0.user.id == newUser.id }
                if athletes.count != 1 {
                    print("Invalid athletes count, returning...")
                } else {
                    newAthlete = athletes[0]
                }
                
                loaded = true
            }
        }
    }
}

struct PostsView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Namespace var namespace
    @State private var posts: [PostProfileItem] = []
    @State private var postShowing: String? = nil
    var newUser: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        let size: CGFloat = 125
        
        ZStack {
            if let showingId = postShowing {
                ForEach($posts) { post in
                    if post.post.wrappedValue.id == showingId {
                        AnyView(post.expandedView.wrappedValue)
                    }
                }
            }
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [
                    GridItem(.fixed(size)), GridItem(.fixed(size)), GridItem(.fixed(size))]) {
                        ForEach($posts, id: \.id) { post in
                            ZStack {
                                AnyView(post.collapsedView.wrappedValue)
                                    .frame(width: size, height: size)
                            }
                        }
                    }
                    .padding(.top)
            }
        }
        .onAppear {
            Task {
                let pred = Post.keys.newuserID == newUser.id
                let postModels: [Post] = try await query(where: pred)
                var profileItems: [PostProfileItem] = []
                for post in postModels {
                    try await profileItems.append(PostProfileItem(post: post, email: newUser.email, namespace: namespace, postShowing: $postShowing))
                }
                
                // Sorts descending by date so most recent posts appear first
                posts = profileItems.sorted(by: {
                    $0.post.creationDate > $1.post.creationDate
                })
            }
        }
    }
}

struct SavedPostsView: View {
    var body: some View {
        Text("Saved Posts View")
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

struct FavoritesView: View {
    @Environment(\.getUser) private var getUser
    @State private var followedUsers: [Followed] = []
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    var newUser: NewUser
    
    private let cornerRadius: CGFloat = 30
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    // Gets DiveMeetsID from followed entity to get ProfileImage for the list
    private func getDiveMeetsID(followed: Followed) -> String? {
        if let diveMeetsID = followed.diveMeetsID {
            return diveMeetsID
        } else if let email = followed.email,
                  let user = getUser(email),
                  let diveMeetsID = user.diveMeetsID {
            return diveMeetsID
        } else {
            return nil
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(followedUsers, id: \.self) { followed in
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Custom.specialGray)
                            .shadow(radius: 5)
                        HStack(alignment: .center) {
                            ProfileImage(diverID: getDiveMeetsID(followed: followed) ?? "")
                                .frame(width: 100, height: 100)
                                .scaleEffect(0.3)
                            HStack(alignment: .firstTextBaseline) {
                                Text((followed.firstName ?? "") + " " + (followed.lastName ?? ""))
                                    .padding()
                                Text(followed.email == nil ? "DiveMeets" : "Adrenaline")
                                    .foregroundColor(Custom.secondaryColor)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .padding([.leading, .trailing])
                }
            }
            .padding(.top)
            .padding(.bottom, maxHeightOffset)
        }
    }
}
