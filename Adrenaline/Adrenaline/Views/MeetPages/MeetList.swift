//
//  MeetList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

// Global that keeps main meet links for each diverID
//                        [diverId:[meetName: meetLink]]
var profileMainMeetLinks: [String: [String: String]] = [:]

// Global that tracks the expansion states of each MeetEvent when navigating through NavigationLinks
var lastExpanded: [String: Bool] = [:]

struct MeetList: View {
    @Environment(\.colorScheme) var currentMode
    var profileLink: String
    @State var diverData: [Int:[String:[String:(String, Double, String, String)]]] = [:]
    @State var offset: CGFloat = 0
    @State var lastOffset: CGFloat = 0
    @State var meets: [MeetEvent] = []
    @State private var createdMeets: Bool = false
    @State var navStatus: Bool = true
    var nameShowing: Bool = true
    @StateObject private var parser = EventHTMLParser()
    
    // Style adjustments for elements of list
    private let frameWidth: CGFloat = 350
    private let frameHeight: CGFloat = 50
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 10
    private let fontSize: CGFloat = 20
    var screenHeight = UIScreen.main.bounds.height
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
    }
    
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    func createMeets(data: [Int:[String:[String:(String, Double, String, String)]]]) -> [MeetEvent]? {
        var mainMeetLink: String = ""
        
        if data.count < 1 {
            return nil
        }
        
        var meets = [MeetEvent]()
        var currentMeetEvents: [MeetEvent]? = []
        
        //Starting at 1 because the first meet in the dictionary has a key of 1
        for i in 1...diverData.count{
            if let value = diverData[i] {
                for (name, meetEvent) in value{
                    for event in meetEvent {
                        let(place, score, link, meetLink) = event.value
                        mainMeetLink = meetLink
                        currentMeetEvents!.append(MeetEvent(name: event.key, place: Int(place),
                                                            score: score, isChild: true, link: link))
                    }
                    let meet = MeetEvent(name: name, children: currentMeetEvents, link: mainMeetLink)
                    meets.append(meet)
                    currentMeetEvents = []
                }
            }
        }
        return meets
    }
    
    
    var body: some View {
        ZStack {
            
            if meets != [] {
                
                ZStack {
                    Rectangle()
                        .fill(bgColor)
                        .mask(RoundedRectangle(cornerRadius: 40))
                    VStack {
                        if nameShowing {
                            Text("Meets")
                                .font(.title2).fontWeight(.semibold)
                                .padding(.top, 30)
                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: rowSpacing) {
                                ForEach($meets, id: \.id) { $meet in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(Custom.darkGray)
                                            .shadow(radius: 5)
                                        DisclosureGroup(
                                            isExpanded: $meet.isExpanded,
                                            content: {
                                                VStack(spacing: 5) {
                                                    Divider()
                                                    
                                                    ChildrenView(children: meet.children)
                                                    
                                                    HStack {
                                                        let shape = RoundedRectangle(cornerRadius: 30)
                                                        
                                                        NavigationLink(
                                                            destination: MeetPageView(
                                                                meetLink: meet.link ?? "")) {
                                                                    ZStack {
                                                                        shape.fill(Custom.grayThinMaterial)
                                                                        Text("Full Meet")
                                                                            .foregroundColor(.primary)
                                                                    }
                                                                    .frame(width: 130, height: 50)
                                                                    .contentShape(shape)
                                                                }
                                                        
                                                        Spacer()
                                                    }
                                                    .padding(.bottom)
                                                    .padding(.top, 5)
                                                }
                                            },
                                            label: {
                                                ParentView(meet: $meet)
                                            }
                                        )
                                        .padding([.leading, .trailing])
                                        // This mechanism using lastExpanded stores the
                                        // expansion state of all values in the list when you
                                        // tap a NavigationLink, and when you return, it pulls
                                        // the isExpanded state from lastExpanded into each meet
                                        // and then removes that value from isExpanded. This
                                        // keeps lastExpanded empty when in a ProfileView and
                                        // populated when you press a NavigationLink
                                        .onAppear {
                                            if let val = lastExpanded[meet.name] {
                                                meet.isExpanded = val
                                                lastExpanded.removeValue(forKey: meet.name)
                                            }
                                        }
                                        .onDisappear {
                                            lastExpanded[meet.name] = meet.isExpanded
                                        }
                                    }
                                    .padding([.leading, .trailing])
                                    .padding(.top, meet == meets.first ? rowSpacing : 0)
                                    .padding(.bottom, meet == meets.last ? rowSpacing : 0)
                                }
                            }
                        }
                    }
                }
                // Waiting for parse results to finish
            } else if !createdMeets {
                
                ZStack {
                    Rectangle()
                        .fill(bgColor)
                        .mask(RoundedRectangle(cornerRadius: 40))
                    VStack {
                        Text("Getting meets list...")
                        ProgressView()
                    }
                }
                // Parse results have finished and meet list is empty
            } else {
                ZStack {
                    Rectangle()
                        .fill(bgColor)
                        .mask(RoundedRectangle(cornerRadius: 40))
                    VStack {
                        Text("No meet data found")
                    }
                }
            }
        }
        .onAppear {
            // Have to check if meets is empty to clear lastExpanded (meaning you have initially
            // opened a new ProfileView)
            if meets == [] {
                lastExpanded = [:]
            }
            
            // Keeps reparsing from being run when stepping back from NavigationLink
            if !createdMeets {
                Task {
                    if let links = profileMainMeetLinks[String(profileLink.components(separatedBy: "=").last ?? "")] {
                        parser.cachedMainMeetLinks = links
                    }
                    await parser.parse(urlString: profileLink)
                    profileMainMeetLinks[String(profileLink.components(separatedBy: "=").last ?? "")] = parser.cachedMainMeetLinks
                    
                    diverData = parser.myData
                    
                    meets = createMeets(data: diverData) ?? []
                    createdMeets = true
                }
            }
        }
    }
}

struct ChildrenView: View {
    var children: [MeetEvent]?
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(children ?? [], id: \.id) { event in
                let shape = RoundedRectangle(cornerRadius: 30)
                ZStack {
                    shape.fill(Custom.grayThinMaterial)
                    ChildView(meet: event, navStatus: event.firstNavigation)
                }
                .contentShape(shape)
            }
        }
    }
}

struct ChildView: View{
    var meet: MeetEvent
    var navStatus: Bool
    
    var body: some View {
        NavigationLink {
            Event(isFirstNav: navStatus, meet: meet)
        } label: {
            HStack {
                Text(meet.name)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
        }
        .foregroundColor(.primary)
        .padding()
    }
}

struct ParentView: View{
    @Binding var meet: MeetEvent
    
    var body: some View {
        HStack {
            Spacer()
            
            Text(meet.name)
                .foregroundColor(.primary)
                .padding()
            
            Spacer()
        }
    }
}

