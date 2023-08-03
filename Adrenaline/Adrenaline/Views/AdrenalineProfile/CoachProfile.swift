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
    @Binding var userViewData: UserViewData
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        VStack {
            Spacer()
            // Showing DiveMeets Linking Screen
            if userViewData.diveMeetsID == "" {
                BackgroundBubble(vPadding: 20, hPadding: 20) {
                    NavigationLink(destination: {
                        DiveMeetsLink(userViewData: $userViewData)
                    }, label: {
                        Text("Link DiveMeets Account")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                    })
                }
            } else {
                CoachProfileContent(userViewData: $userViewData)
                    .padding(.top, screenHeight * 0.05)
            }
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
}


struct CoachProfileContent: View {
    @StateObject private var parser = ProfileParser()
    @State var scoreValues: [String] = ["Judging", "Divers", "Metrics", "Recruiting", "Statistics"]
    @State var selectedPage: Int = 1
    @State var profileLink: String = ""
    @Binding var userViewData: UserViewData
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenHeight = UIScreen.main.bounds.height
    
    private var diveMeetsID: String {
        guard let nums = profileLink.split(separator: "=", maxSplits: 1).last else { return "" }
        return String(nums)
    }
    
    var body: some View {
        SwiftUIWheelPicker($selectedPage, items: scoreValues) { value in
            GeometryReader { g in
                Text(value)
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
            profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (userViewData.diveMeetsID ?? "")
            Task {
                if !cachedJudging.keys.contains(diveMeetsID) ||
                    !cachedDivers.keys.contains(diveMeetsID) {
                    if await !parser.parseProfile(link: profileLink) {
                        print("Failed to parse profile")
                    }
                    
                    cachedJudging[diveMeetsID] = parser.profileData.judging
                    cachedDivers[diveMeetsID] = parser.profileData.coachDivers
                }
            }
        }
        
        switch selectedPage {
        case 0:
            if let judging = cachedJudging[diveMeetsID] {
                JudgedList(data: judging)
            } else {
                    BackgroundBubble() {
                        VStack {
                            Text("Getting judging data...")
                            ProgressView()
                        }
                        .padding()
                    }
                }
        case 1:
            if let divers = cachedDivers[diveMeetsID] {
                DiversList(divers: divers)
                    .offset(y: -20)
            } else {
                BackgroundBubble() {
                    VStack {
                        Text("Getting coach divers list...")
                        ProgressView()
                    }
                    .padding()
                }
            }
        case 2:
            CoachMetricsView()
        case 3:
            CoachRecruitingView()
        case 4:
            CoachStatisticsView()
        default:
            if let judging = cachedJudging[diveMeetsID] {
                JudgedList(data: judging)
            }
        }
        Spacer()
    }
}

struct CoachMetricsView: View {
    var body: some View{
        Text("Coach Metrics")
    }
}

struct CoachRecruitingView: View {
    var body: some View{
        Text("Coach Recruiting")
    }
}

struct CoachStatisticsView: View {
    var body: some View{
        Text("Coach Statistics")
    }
}

