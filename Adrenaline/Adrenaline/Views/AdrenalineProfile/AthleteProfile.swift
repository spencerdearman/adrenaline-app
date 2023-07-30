//
//  AthleteProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI

struct DiverView: View {
    @Binding var user: User
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
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
                ProfileContent(user: $user)
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

struct ProfileContent: View {
    @State var scoreValues: [String] = ["Meets", "Metrics", "Recruiting", "Statistics", "Videos"]
    @State var selectedPage: Int = 1
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
        
        switch selectedPage {
        case 0:
            MeetList(profileLink:
                    "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                     (user.diveMeetsID ?? "00000"), nameShowing: false)
                .offset(y: -screenHeight * 0.05)
        case 1:
            MetricsView(user: $user)
        case 2:
            RecruitingView()
        case 3:
            StatisticsView()
        case 4:
            VideosView()
        default:
            MeetList(profileLink:
                     "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                     (user.diveMeetsID ?? "00000"), nameShowing: false)
        }
    }
}

struct MetricsView: View {
    @Binding var user: User
    var body: some View {
        let profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (user.diveMeetsID ?? "00000")
        SkillsGraph(profileLink: profileLink)
//            .frame(height: 300)
    }
}

struct RecruitingView: View {
    var body: some View {
        Text("Welcome to the Recruiting View")
    }
}

struct VideosView: View {
    var body: some View {
        Text("Welcome to the Videos View")
    }
}

struct StatisticsView: View {
    var body: some View {
        Text("Welcome to the Statistics View")
    }
}
