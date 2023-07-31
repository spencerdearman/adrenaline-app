//
//  ProfileView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI
import SwiftSoup

var entriesHtmlCache: [String: String] = [:]

struct ProfileView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    
    var profileLink: String
    var isLoginProfile: Bool = false
    @Namespace var profilespace
    @State var diverTab: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    @StateObject private var parser = ProfileParser()
    @State private var isExpanded: Bool = false
    private let getTextModel = GetTextAsyncModel()
    private let ep = EntriesParser()
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let shadowRadius: CGFloat = 5
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private var profileType: String {
        parser.profileData.coachDivers == nil ? "Diver" : "Coach"
    }
    
    private func isDictionary(_ object: Any) -> Bool {
        let mirror = Mirror(reflecting: object)
        return mirror.displayStyle == .dictionary
    }
    
    private func getEntriesHtml(link: String) -> String {
        if entriesHtmlCache.keys.contains(link) { return entriesHtmlCache[link]! }
        Task {
            guard let url = URL(string: link) else { return "" }
            await getTextModel.fetchText(url: url)
            
            if let text = getTextModel.text {
                entriesHtmlCache[link] = text
                return text
            }
            
            return ""
        }
        
        return ""
    }
    
    var body: some View {
        
        ZStack {
            let infoSafe = parser.profileData.info != nil
            let info = parser.profileData.info
            let name = info?.name
            let diverId = info?.diverId ?? ""
            let cityState = info?.cityState
            let country = info?.country
            let gender = info?.gender
            let age = info?.age
            let finaAge = info?.finaAge
            
            if !isLoginProfile {
                bgColor.ignoresSafeArea()
                GeometryReader { geometry in
                    BackgroundSpheres()
                }
            } else {
                Color.clear.ignoresSafeArea()
            }
            
            if profileType == "Diver" {
                ZStack {
                    VStack {
                        ProfileImage(diverID: diverId)
                            .frame(width: 200, height: 150)
                            .scaleEffect(0.9)
                            .padding(.top)
                            .padding()
                        VStack {
                            BackgroundBubble(vPadding: 40, hPadding: 60) {
                                VStack() {
                                    HStack (alignment: .firstTextBaseline) {
                                        if infoSafe, let name = name {
                                            Text(name)
                                                .font(.title3).fontWeight(.semibold)
                                        } else {
                                            Text("")
                                        }
                                    }
                                    Divider()
                                    HStack (alignment: .firstTextBaseline) {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
                                            if infoSafe,
                                               let cityState = cityState,
                                               let country = country {
                                                Text(cityState)
                                            } else {
                                                Text("")
                                            }
                                        }
                                        HStack {
                                            Image(systemName: "person.fill")
                                            if infoSafe, let age = age {
                                                Text("Age: " + String(age))
                                            } else {
                                                Text("")
                                            }
                                        }
                                        HStack {
                                            Image(systemName: "figure.pool.swim")
                                            Text(diverId)
                                        }
                                    }
                                    .padding([.leading], 2)
                                }
                            }
                        }
                        .frame(width: screenWidth * 0.8)
                        .padding([.leading, .trailing, .top])
                        
                        if let upcomingMeets = parser.profileData.upcomingMeets {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(.white)
                                    .shadow(radius: 5)
                                
                                DisclosureGroup(isExpanded: $isExpanded) {
                                    ForEach(upcomingMeets.sorted(by: { $0.name < $1.name }),
                                            id: \.self) { meet in
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(meet.name)
                                                .font(.title3)
                                                .bold()
                                            VStack(spacing: 5) {
                                                ForEach(meet.events.sorted(by: {
                                                    $0.name < $1.name
                                                }), id: \.self) { event in
                                                    let html = getEntriesHtml(link: event.link)
                                                    if let name = name,
                                                       let entry = ep.parseNamedEntry(
                                                        html: html,
                                                        searchName: name) {
                                                        EntryView(entry: entry) {
                                                            Text(event.name)
                                                                .font(.headline)
                                                                .bold()
                                                                .foregroundColor(Color.primary)
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.leading)
                                            .padding(.top, 5)
                                        }
                                        .padding(.top, 5)
                                    }
                                            .padding()
                                } label: {
                                    Text("Upcoming Meets")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(Color.primary)
                                }
                                .padding([.leading, .trailing])
                                .padding(.bottom, 5)
                            }
                            .padding([.leading, .trailing])
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        
                        MeetList(profileLink: profileLink)
                        
                    }
                    .padding(.bottom, maxHeightOffset)
                }
            } else {
                ZStack {
                    GeometryReader { geometry in
                        BackgroundSpheres()
                        Rectangle()
                            .fill(bgColor)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .offset(y: geometry.size.height * 0.4)
                    }
                    VStack {
                        VStack {
                            ProfileImage(diverID: diverId)
                                .frame(width: 200, height: 150)
                                .padding()
                            VStack {
                                VStack(alignment: .leading) {
                                    HStack(alignment: .firstTextBaseline) {
                                        if infoSafe, let name = name {
                                            Text(name)
                                                .font(.title)
                                                .foregroundColor(.white)
                                        } else {
                                            Text("")
                                        }
                                    }
                                    WhiteDivider()
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: "house.fill")
                                        if infoSafe, let cityState = cityState,
                                           let country = country {
                                            Text(cityState + ", " + country)
                                        } else {
                                            Text("")
                                        }
                                    }
                                    .font(.subheadline).foregroundColor(.white)
                                    HStack (alignment: .firstTextBaseline) {
                                        Image(systemName: "person.circle")
                                        if infoSafe, let gender = gender {
                                            Text("Gender: " + gender)
                                        } else {
                                            Text("")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding([.leading], 2)
                                }
                            }
                            .padding()
                            if !diverTab {
                                VStack{
                                    Spacer()
                                }
                                .frame(width: 100, height: 50)
                                .foregroundStyle(.white)
                                .background(
                                    Custom.specialGray.matchedGeometryEffect(id: "background",
                                                                             in: profilespace)
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                                        .matchedGeometryEffect(id: "mask", in: profilespace)
                                )
                                .shadow(radius: 5)
                                .overlay(
                                    ZStack {
                                        Text("Divers")
                                            .font(.title3).fontWeight(.semibold)
                                            .matchedGeometryEffect(id: "title", in: profilespace)
                                    })
                                .padding(.top, 8)
                                .onTapGesture{
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        diverTab.toggle()
                                    }
                                }
                            } else {
                                ZStack {
                                    VStack {
                                        Text("Divers")
                                            .padding(.top)
                                            .font(.title3).fontWeight(.semibold)
                                            .matchedGeometryEffect(id: "title", in: profilespace)
                                            .onTapGesture{
                                                withAnimation(.spring(response: 0.6,
                                                                      dampingFraction: 0.8)) {
                                                    diverTab.toggle()
                                                }
                                            }
                                        if let divers = parser.profileData.coachDivers {
                                            DiversList(divers: divers)
                                                .offset(y: -20)
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .background(
                                    Custom.darkGray.matchedGeometryEffect(id: "background",
                                                                          in: profilespace)
                                )
                                .mask(
                                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                                        .matchedGeometryEffect(id: "mask", in: profilespace)
                                )
                                .shadow(radius: 10)
                                .frame(width: 375, height: 300)
                            }
                            if let judging = parser.profileData.judging {
                                JudgedList(data: judging)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                if parser.profileData.info == nil {
                    if await !parser.parseProfile(link: profileLink) {
                        print("Failed to parse profile")
                    }
                }
                if let stats = parser.profileData.diveStatistics {
                    let skill = SkillRating(diveStatistics: stats)
                    let divesByCategory = skill.getDiverStatsByCategory()
                    let (springboard, platform, total) = await skill
                        .getSkillRating(link: profileLink, metric: skill.computeMetric1)
                    print(String(format: "Springboard: %.2f", springboard))
                    print(String(format: "Platform: %.2f", platform))
                    print(String(format: "Total: %.2f", total))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !isLoginProfile {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        NavigationViewBackButton()
                    }
                }
            }
        }
    }
}

struct DiversList: View {
    var divers: [DiverInfo]
    
    var body: some View {
        VStack (spacing: 1) {
            TabView {
                ForEach(divers, id: \.self) { elem in
                    DiverBubbleView(element: elem)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 190)
        }
    }
}

struct DiverBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @State private var focusBool: Bool = false
    private let getTextModel = GetTextAsyncModel()
    
    var element: DiverInfo
    
    var body: some View {
        NavigationLink {
            ProfileView(profileLink: element.link)
        } label: {
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .cornerRadius(30)
                    .frame(width: 300, height: 100)
                    .shadow(radius: 5)
                HStack {
                    Text(element.name)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    
                    MiniProfileImage(diverID: element.diverId, width: 80, height: 100)
                        .padding(.leading)
                        .scaledToFit()
                }
            }
        }
    }
}

struct JudgedList: View {
    var data: ProfileJudgingData
    
    let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 10
    
    var body: some View {
        
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: rowSpacing) {
                    ForEach(data, id: \.self) { meet in
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Custom.darkGray)
                                .shadow(radius: 5)
                            DisclosureGroup(
                                content: {
                                    VStack(spacing: 5) {
                                        ForEach(meet.events, id: \.self) { event in
                                            let shape = RoundedRectangle(cornerRadius: 50)
                                            NavigationLink(destination:
                                                            EventResultPage(meetLink: event.link))
                                            {
                                                ZStack {
                                                    shape.fill(Custom.grayThinMaterial)
                                                    
                                                    HStack {
                                                        Text(event.name)
                                                            .lineLimit(1)
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.blue)
                                                    }
                                                    .frame(height: 35)
                                                    .padding(14)
                                                    
                                                }
                                                .foregroundColor(.primary)
                                                .padding([.leading, .trailing])
                                            }
                                        }
                                    }
                                    .padding(.bottom)
                                },
                                label: {
                                    Text(meet.name)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Custom.textColor)
                                        .padding()
                                }
                            )
                            .padding([.leading, .trailing])
                        }
                        .padding([.leading, .trailing])
                    }
                }
                .padding([.top, .bottom], rowSpacing)
            }
        }
    }
}
