//
//  CoachProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI

struct CoachView: View {
    @Binding var user: User
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        VStack {
            Spacer()
            // Showing DiveMeets Linking Screen
            if user.diveMeetsID == "" {
                BackgroundBubble(vPadding: 20, hPadding: 20) {
                    NavigationLink(destination: {
                        DiveMeetsLink(user: $user)
                    }, label: {
                        Text("Link DiveMeets Account")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                    })
                }
            } else {
                CoachProfileContent(user: $user)
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
    @Binding var user: User
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenHeight = UIScreen.main.bounds.height
    
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
            profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (user.diveMeetsID ?? "")
            Task {
                if parser.profileData.info == nil {
                    if await !parser.parseProfile(link: profileLink) {
                        print("Failed to parse profile")
                    }
                }
            }
        }
        
        switch selectedPage {
        case 0:
            if let judging = parser.profileData.judging {
                JudgedList(data: judging)
            }
        case 1:
            if let divers = parser.profileData.coachDivers {
                DiversList(divers: divers)
                    .offset(y: -20)
            }
        case 2:
            CoachMetricsView()
        case 3:
            CoachRecruitingView()
        case 4:
            CoachStatisticsView()
        default:
            if let judging = parser.profileData.judging {
                JudgedList(data: judging)
            }
        }
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

