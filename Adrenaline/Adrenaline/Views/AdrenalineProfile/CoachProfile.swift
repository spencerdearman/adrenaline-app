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
    @State var scoreValues: [String] = ["Posts", "Recruiting", "Judging", "Divers"]
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
            switch scoreValues[selectedPage] {
                case "Posts":
                    PostsView(newUser: newUser)
                case "Judging":
                    JudgingView(newUser: newUser, judgingData: judgingData)
                case "Divers":
                    DiversView(newUser: newUser, diversData: coachDiversData)
                case "Recruiting":
                    CoachRecruitingView(newUser: newUser)
                case "Saved":
                    SavedPostsView(newUser: newUser)
                case "Favorites":
                    FavoritesView(newUser: newUser)
                default:
                    Text("Default View")
            }
        }
        .offset(y: -screenHeight * 0.05)
        Spacer()
    }
}

struct CoachRecruitingView: View {
    var newUser: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
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
        }
        .padding()
    }
}

struct JudgingView: View {
    var newUser: NewUser
    var judgingData: ProfileJudgingData?
    
    var body: some View {
        ZStack {
            if let diveMeetsID = newUser.diveMeetsID, diveMeetsID != "" {
                if let data = judgingData {
                    Text("Judging")
                        .foregroundColor(.primary)
                } else {
                    Text("No Judging Data Found")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No DiveMeets Account Linked")
                    .foregroundColor(.secondary)
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .padding()
        .multilineTextAlignment(.center)
    }
}

struct DiversView: View {
    var newUser: NewUser
    var diversData: ProfileCoachDiversData?
    
    var body: some View {
        ZStack {
            if let diveMeetsID = newUser.diveMeetsID, diveMeetsID != "" {
                if let data = diversData {
                    Text("Divers")
                        .foregroundColor(.primary)
                } else {
                    Text("No Diver Data Found")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No DiveMeets Account Linked")
                    .foregroundColor(.secondary)
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .padding()
        .multilineTextAlignment(.center)
    }
}
