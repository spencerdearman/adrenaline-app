//
//  AthleteProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI

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
    @State var scoreValues: [String] = ["Meets", "Metrics", "Recruiting", "Statistics", "Videos"]
    @State var selectedPage: Int = 0
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
        }
        
        Group {
            switch selectedPage {
                case 0:
                    AnyView(MeetListView(diveMeetsID: graphUser.diveMeetsID, nameShowing: false))
                case 1:
                    AnyView(MetricsView(graphUser: graphUser))
                case 2:
                    AnyView(RecruitingView())
                case 3:
                    AnyView(StatisticsView(diveMeetsID: graphUser.diveMeetsID))
                case 4:
                    AnyView(VideosView())
                case 5:
                    AnyView(FavoritesView(graphUser: graphUser))
                default:
                    AnyView(MeetListView(diveMeetsID: graphUser.diveMeetsID, nameShowing: false))
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
    var graphUser: GraphUser
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if let diveMeetsID = graphUser.diveMeetsID {
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

struct RecruitingView: View {
    var body: some View {
        Text("Welcome to the Recruiting View")
    }
}

struct VideosView: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Environment(\.videoStore) private var videoStore
    @State private var videos: [VideoItem] = []
    @State private var isDownloading: Bool = false
    @AppStorage("email") private var email: String = ""
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        VStack {
            if !videos.isEmpty {
                let size: CGFloat = 125
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.fixed(size)), GridItem(.fixed(size)), GridItem(.fixed(size))]) {
                            ForEach(videos.indices, id: \.self) { index in
                                videos[index].view
                                    .frame(width: size, height: size)
                                    .onAppear {
                                        videos[index].player?.seek(to: .zero)
                                    }
                            }
                        }
                }
            } else {
                Spacer()
            }
            
            if isDownloading {
                BackgroundBubble(vPadding: 20, hPadding: 40) {
                    VStack {
                        Text("Getting videos...")
                        ProgressView()
                    }
                }
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .padding([.leading, .trailing, .bottom])
        .onAppear {
            if videos.isEmpty, email != "" {
                Task {
                    guard let listItems = await videoStore.getVideoItemsByEmail(email: email) else {
                        return
                    }
                    
                    isDownloading = true
                    
                    videos = await withTaskGroup(of: (Int, VideoItem?).self,
                                                 returning: [VideoItem].self) { [self] group in
                        // Associates each work item with an Int to achieve original order later
                        for item in listItems.enumerated().map({ ($0.0, $0.1) }) {
                            group.addTask {
                                await (item.0, videoStore.downloadVideoItem(item: item.1,
                                                                            email: email))
                            }
                        }
                        
                        var results: [(Int, VideoItem)] = []
                        
                        for await result in group {
                            if result.1 != nil {
                                results.append((result.0, result.1!))
                            }
                        }
                        
                        return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
                    }
                    
                    isDownloading = false
                }
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
            .onChange(of: maxHeightOffsetScaled) { _ in
                print(maxHeightOffset)
            }
            .onAppear {
                if stats.isEmpty, let diveMeetsID = diveMeetsID {
                    Task {
                        if await parser.parseProfile(diveMeetsID: diveMeetsID) {
                            
                            guard let parsedStats = parser.profileData.diveStatistics else { return }
                            stats = parsedStats
                            filteredStats = stats
                        } else {
                            print("Failed to parse profile")
                        }
                    }
                }
            }
        }
        .onChange(of: categorySelection) { _ in
            updateFilteredStats()
        }
        .onChange(of: heightSelection) { _ in
            updateFilteredStats()
        }
    }
}

struct FavoritesView: View {
    @Environment(\.getUser) private var getUser
    @State private var followedUsers: [Followed] = []
    var graphUser: GraphUser
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
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
