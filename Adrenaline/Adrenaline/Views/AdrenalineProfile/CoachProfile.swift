//
//  CoachProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI

//                 [diveMeetsID: JudgingData]
var cachedJudging: [String: ProfileJudgingData] = [:]
//                [diveMeetsID: DiversData]
var cachedDivers: [String: ProfileCoachDiversData] = [:]

struct CoachView: View {
    var newUser: NewUser
    @ScaledMetric private var linkButtonWidthScaled: CGFloat = 300
    
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var linkButtonWidth: CGFloat {
        min(linkButtonWidthScaled, screenWidth * 0.8)
    }
    
    var body: some View {
        VStack {
            Spacer()
            CoachProfileContent(newUser: newUser)
                .padding(.top, screenHeight * 0.05)
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
}


struct CoachProfileContent: View {
    @AppStorage("authUserId") private var authUserId: String = ""
    @StateObject private var parser = ProfileParser()
    @State var scoreValues: [String] = ["Posts", "Judging", "Divers", "Metrics", "Recruiting",
                                        "Statistics"]
    @State var selectedPage: Int = 0
    @State var profileLink: String = ""
    @State var judgingData: ProfileJudgingData? = nil
    @State var coachDiversData: ProfileCoachDiversData? = nil
    var newUser: NewUser
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var diveMeetsID: String {
        newUser.diveMeetsID ?? ""
    }
    
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
            Task {
                profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (diveMeetsID)
                
                // If viewing the user's own profile, show Saved and Favorites tab
                if newUser.id == authUserId {
                    scoreValues += ["Saved", "Favorites"]
                }
                
                if !cachedJudging.keys.contains(diveMeetsID) ||
                    !cachedDivers.keys.contains(diveMeetsID) {
                    if await !parser.parseProfile(link: profileLink) {
                        print("Failed to parse profile")
                    }
                    
                    cachedJudging[diveMeetsID] = parser.profileData.judging
                    cachedDivers[diveMeetsID] = parser.profileData.coachDivers
                }
                
                judgingData = cachedJudging[diveMeetsID]
                coachDiversData = cachedDivers[diveMeetsID]
            }
        }
        
        Group {
            switch selectedPage {
                case 0:
                    PostsView(newUser: newUser)
                case 1:
                    if let judging = judgingData {
//                        JudgedList(data: judging)
                    } else if diveMeetsID == "" {
                        BackgroundBubble() {
                            Text("Cannot get judging data, account is not linked to DiveMeets")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(width: screenWidth * 0.9)
                    } else {
                        BackgroundBubble(vPadding: 40, hPadding: 40) {
                            VStack {
                                Text("Getting judging data...")
                                ProgressView()
                            }
                        }
                    }
                case 2:
                    if let divers = coachDiversData {
//                        DiversList(divers: divers)
//                            .offset(y: -20)
                    } else if diveMeetsID == "" {
                        BackgroundBubble() {
                            Text("Cannot get diver data, account is not linked to DiveMeets")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(width: screenWidth * 0.9)
                    } else {
                        BackgroundBubble(vPadding: 40, hPadding: 40) {
                            VStack {
                                Text("Getting coach divers list...")
                                ProgressView()
                            }
                        }
                    }
                case 3:
                    CoachMetricsView()
                case 4:
                    CoachRecruitingView()
                case 5:
                    CoachStatisticsView()
                case 6:
                    SavedPostsView(newUser: newUser)
                case 7:
                    FavoritesView(newUser: newUser)
                default:
                    if let judging = judgingData {
//                        JudgedList(data: judging)
                    }
            }
        }
        .offset(y: -screenHeight * 0.05)
        Spacer()
    }
}

struct CoachMetricsView: View {
    var body: some View {
        Text("Coach Metrics")
    }
}

struct CoachRecruitingView: View {
    var body: some View {
        Text("Coach Recruiting")
    }
}

struct CoachStatisticsView: View {
    var body: some View {
        Text("Coach Statistics")
    }
}

