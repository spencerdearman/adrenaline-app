////
////  CoachProfile.swift
////  Adrenaline
////
////  Created by Spencer Dearman on 7/29/23.
////
//
//import SwiftUI
//
////                 [diveMeetsID: JudgingData]
//var cachedJudging: [String: ProfileJudgingData] = [:]
////                [diveMeetsID: DiversData]
//var cachedDivers: [String: ProfileCoachDiversData] = [:]
//
//struct CoachView: View {
//    @Binding var userViewData: UserViewData
//    @Binding var loginSuccessful: Bool
//    @ScaledMetric private var linkButtonWidthScaled: CGFloat = 300
//
//    private let linkHead: String =
//    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
//    private let screenWidth = UIScreen.main.bounds.width
//    private let screenHeight = UIScreen.main.bounds.height
//
//    private var linkButtonWidth: CGFloat {
//        min(linkButtonWidthScaled, screenWidth * 0.8)
//    }
//
//    var body: some View {
//        VStack {
//            Spacer()
//            // Showing DiveMeets Linking Screen
//            if (userViewData.diveMeetsID == nil || userViewData.diveMeetsID == "") &&
//                loginSuccessful {
//                NavigationLink(destination: {
//                    DiveMeetsLink(userViewData: $userViewData)
//                }, label: {
//                    ZStack {
//                        Rectangle()
//                            .foregroundColor(Custom.darkGray)
//                            .cornerRadius(50)
//                            .shadow(radius: 10)
//                        Text("Link DiveMeets Account")
//                            .foregroundColor(.primary)
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                            .padding()
//                    }
//                    .frame(width: linkButtonWidth, height: screenHeight * 0.05)
//                })
//                Spacer()
//                Spacer()
//                Spacer()
//            } else {
//                CoachProfileContent(userViewData: $userViewData)
//                    .padding(.top, screenHeight * 0.05)
//            }
//            Spacer()
//            Spacer()
//            Spacer()
//            Spacer()
//            Spacer()
//        }
//    }
//}
//
//
//struct CoachProfileContent: View {
//    @StateObject private var parser = ProfileParser()
//    @State var scoreValues: [String] = ["Judging", "Divers", "Metrics", "Recruiting", "Statistics"]
//    @State var selectedPage: Int = 1
//    @State var profileLink: String = ""
//    @State var judgingData: ProfileJudgingData? = nil
//    @State var coachDiversData: ProfileCoachDiversData? = nil
//    @Binding var userViewData: UserViewData
//    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
//    private let screenWidth = UIScreen.main.bounds.width
//    private let screenHeight = UIScreen.main.bounds.height
//
//    private var diveMeetsID: String {
//        userViewData.diveMeetsID ?? ""
//    }
//
//    var body: some View {
//        SwiftUIWheelPicker($selectedPage, items: scoreValues) { value in
//            GeometryReader { g in
//                Text(value)
//                    .dynamicTypeSize(.xSmall ... .xLarge)
//                    .font(.title2).fontWeight(.semibold)
//                    .frame(width: g.size.width, height: g.size.height,
//                           alignment: .center)
//            }
//        }
//        .scrollAlpha(0.3)
//        .width(.Fixed(115))
//        .scrollScale(0.7)
//        .frame(height: 40)
//        .onAppear {
//            profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (userViewData.diveMeetsID ?? "")
//            Task {
//                if !cachedJudging.keys.contains(diveMeetsID) ||
//                    !cachedDivers.keys.contains(diveMeetsID) {
//                    if await !parser.parseProfile(link: profileLink) {
//                        print("Failed to parse profile")
//                    }
//
//                    cachedJudging[diveMeetsID] = parser.profileData.judging
//                    cachedDivers[diveMeetsID] = parser.profileData.coachDivers
//                }
//
//                judgingData = cachedJudging[diveMeetsID]
//                coachDiversData = cachedDivers[diveMeetsID]
//            }
//        }
//
//        Group {
//            switch selectedPage {
//                case 0:
//                    if let judging = judgingData {
//                        JudgedList(data: judging)
//                    } else if diveMeetsID == "" {
//                        BackgroundBubble() {
//                            Text("Cannot get judging data, account is not linked to DiveMeets")
//                                .font(.title2)
//                                .multilineTextAlignment(.center)
//                                .padding()
//                        }
//                        .frame(width: screenWidth * 0.9)
//                    } else {
//                        BackgroundBubble(vPadding: 40, hPadding: 40) {
//                            VStack {
//                                Text("Getting judging data...")
//                                ProgressView()
//                            }
//                        }
//                    }
//                case 1:
//                    if let divers = coachDiversData {
//                        DiversList(divers: divers)
//                            .offset(y: -20)
//                    } else if diveMeetsID == "" {
//                        BackgroundBubble() {
//                            Text("Cannot get diver data, account is not linked to DiveMeets")
//                                .font(.title2)
//                                .multilineTextAlignment(.center)
//                                .padding()
//                        }
//                        .frame(width: screenWidth * 0.9)
//                    } else {
//                        BackgroundBubble(vPadding: 40, hPadding: 40) {
//                            VStack {
//                                Text("Getting coach divers list...")
//                                ProgressView()
//                            }
//                        }
//                    }
//                case 2:
//                    CoachMetricsView()
//                case 3:
//                    CoachRecruitingView()
//                case 4:
//                    CoachStatisticsView()
//                default:
//                    if let judging = judgingData {
//                        JudgedList(data: judging)
//                    }
//            }
//        }
//        .offset(y: -screenHeight * 0.05)
//        Spacer()
//    }
//}
//
//struct CoachMetricsView: View {
//    var body: some View {
//        Text("Coach Metrics")
//    }
//}
//
//struct CoachRecruitingView: View {
//    var body: some View {
//        Text("Coach Recruiting")
//    }
//}
//
//struct CoachStatisticsView: View {
//    var body: some View {
//        Text("Coach Statistics")
//    }
//}
//
