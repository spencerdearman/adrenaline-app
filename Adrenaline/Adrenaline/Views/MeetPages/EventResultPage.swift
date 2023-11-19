//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI
import Amplify

struct EventResultPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var parser = EventPageHTMLParser()
    @State var eventTitle: String = ""
    @State var meetLink: String
    @State var resultData: [[String]] = []
    @State var alreadyParsed: Bool = false
    @State var timedOut: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        ZStack {
            VStack {
                if alreadyParsed {
                    Text(eventTitle)
                        .font(.title)
                        .bold()
                        .padding()
                        .multilineTextAlignment(.center)
                    Divider()
                    ScalingScrollView(records: resultData, bgColor: .clear, rowSpacing: 10,
                                      shadowRadius: 8) { (elem) in
                        PersonBubbleView(elements: elem, eventTitle: eventTitle)
                    }
                                      .padding(.bottom, maxHeightOffset)
                } else if !timedOut {
                    BackgroundBubble() {
                        VStack {
                            Text("Getting event results...")
                            ProgressView()
                        }
                        .padding()
                    }
                } else {
                    BackgroundBubble() {
                        Text("Unable to get event results, network timed out")
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            Task {
                if !alreadyParsed {
                    let parseTask = Task {
                        await parser.parse(urlString: meetLink)
                        resultData = parser.eventPageData
                        if resultData.count > 0 && resultData[0].count > 8 {
                            eventTitle = resultData[0][8]
                            alreadyParsed = true
                        }
                    }
                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: UInt64(timeoutInterval) * NSEC_PER_SEC)
                        parseTask.cancel()
                        timedOut = true
                    }
                    
                    await parseTask.value
                    timeoutTask.cancel()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
        }
    }
}

struct PersonBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    @State var navStatus: Bool = false
    @State private var diverNewUser: NewUser? = nil
    @State private var synchroNewUser: NewUser? = nil
    
    //  (Place, Name, NameLink, Team, TeamLink, Score, ScoreLink, Score Diff., MeetName, SynchroName,
    //   SynchroLink, SynchroTeam, SynchroTeamLink)
    private var elements: [String]
    private var eventTitle: String
    
    init(elements: [String], eventTitle: String) {
        self.elements = elements
        self.eventTitle = eventTitle
    }
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private var isSynchro: Bool {
        elements.count == 13
    }
    
    private var diverName: some View {
        Text(elements[1])
    }
    
    private var synchroName: some View {
        if elements.count > 9 {
            Text(elements[9])
        } else {
            Text("")
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(35)
            VStack {
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        HStack(spacing: 0) {
                            if let diver = diverNewUser {
                                NavigationLink {
                                    AdrenalineProfileView(newUser: diver)
                                } label: {
                                    diverName
                                        .foregroundColor(.accentColor)
                                }
                            } else {
                                diverName
                                    .foregroundColor(.primary)
                            }
                            
                            if isSynchro {
                                HStack(spacing: 0) {
                                    Text(" / ")
                                    
                                    if let synchro = synchroNewUser {
                                        NavigationLink {
                                            AdrenalineProfileView(newUser: synchro)
                                        } label: {
                                            synchroName
                                                .foregroundColor(.accentColor)
                                        }
                                    } else {
                                        synchroName
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .font(.title3)
                        .bold()
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        
                        (isSynchro
                         ? Text(elements[3] + " / " + elements[11])
                         : Text(elements[3]))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        Spacer()
                    }
                    Spacer()
                    HStack{
                        Text("Place: " + elements[0])
                        Spacer()
                        Text("Score: ")
                        NavigationLink {
                            Event(isFirstNav: navStatus,
                                  meet: MeetEvent(name: eventTitle, link: elements[6],
                                                  firstNavigation: false))
                        } label: {
                            Text(elements[5])
                        }
                        Spacer()
                        Text("Difference: " + elements[7])
                    }
                    .font(.subheadline)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                guard let diveMeetsId = elements[2].split(separator: "=").last else { return }
                let pred = NewUser.keys.diveMeetsID == String(diveMeetsId)
                let users = await queryAWSUsers(where: pred)
                if users.count == 1 {
                    diverNewUser = users[0]
                }
                
                if isSynchro {
                    guard let diveMeetsId = elements[10].split(separator: "=").last else { return }
                    let pred = NewUser.keys.diveMeetsID == String(diveMeetsId)
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        synchroNewUser = users[0]
                    }
                }
            }
        }
    }
}
