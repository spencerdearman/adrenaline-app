//
//  AthleteProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/29/23.
//

import SwiftUI

struct DiverView: View {
    @Binding var userViewData: UserViewData
    @Binding var loginSuccessful: Bool
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
            if (userViewData.diveMeetsID == nil || userViewData.diveMeetsID == "") &&
                loginSuccessful {
                Spacer()
                NavigationLink(destination: {
                    DiveMeetsLink(userViewData: $userViewData)
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
                ProfileContent(userViewData: $userViewData, loginSuccessful: $loginSuccessful)
                    .padding(.top, screenHeight * 0.05)
            }
            Spacer()
        }
    }
}

struct ProfileContent: View {
    @State var scoreValues: [String] = ["Meets", "Metrics", "Recruiting", "Statistics", "Videos"]
    @State var selectedPage: Int = 0
    @Binding var userViewData: UserViewData
    @Binding var loginSuccessful: Bool
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
            if loginSuccessful, scoreValues.last != "Favorites" {
                scoreValues.append("Favorites")
            }
        }
        
        Group {
            switch selectedPage {
                case 0:
                    MeetListView(diveMeetsID: userViewData.diveMeetsID, nameShowing: false)
                case 1:
                    MetricsView(userViewData: $userViewData)
                case 2:
                    RecruitingView()
                case 3:
                    StatisticsView()
                case 4:
                    VideosView()
                case 5:
                    FavoritesView(userViewData: $userViewData)
                default:
                    MeetListView(diveMeetsID: userViewData.diveMeetsID, nameShowing: false)
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
    @Binding var userViewData: UserViewData
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if let diveMeetsID = userViewData.diveMeetsID {
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
    var body: some View {
        Text("Welcome to the Videos View")
    }
}

struct StatisticsView: View {
    var body: some View {
        Text("Welcome to the Statistics View")
    }
}

struct FavoritesView: View {
    @Environment(\.getUser) private var getUser
    @State private var followedUsers: [Followed] = []
    @Binding var userViewData: UserViewData
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
        .onAppear {
            // We can use userViewData email here instead of logged in user because this view
            // should only be visible when viewing the logged in profile
            guard let email = userViewData.email else { return }
            guard let user = getUser(email) else { return }
            followedUsers = user.followedArray
        }
    }
}
