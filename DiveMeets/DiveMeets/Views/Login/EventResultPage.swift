//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI

struct EventResultPage: View {
    @StateObject private var parser = EventPageHTMLParser()
    @State var eventTitle: String = ""
    @State var meetLink: String
    @State var resultData: [[String]] = []
    @State var alreadyParsed: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        ZStack{}
            .onAppear {
                if !alreadyParsed {
                    Task {
                        await parser.parse(urlString: meetLink)
                        resultData = parser.eventPageData
                        eventTitle = resultData[0][8]
                        alreadyParsed = true
                    }
                }
            }
        VStack{
            Text(eventTitle)
                .font(.title)
                .bold()
                .padding()
                .multilineTextAlignment(.center)
            Divider()
            ScalingScrollView(records: resultData) { (elem) in
                PersonBubbleView(elements: elem, eventTitle: eventTitle)
            }
            .padding(.bottom, maxHeightOffset)
        }
    }
}


struct PersonBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    //  (Place, Name, NameLink, Team, TeamLink, Score, ScoreLink, Score Diff., MeetName, SynchroName, SynchroLink, SynchroTeam, SynchroTeamLink)
    private var elements: [String]
    private var eventTitle: String
    @State var navStatus: Bool = false
    
    init(elements: [String], eventTitle: String) {
        self.elements = elements
        self.eventTitle = eventTitle
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(bubbleColor)
            VStack {
                VStack {
                    HStack(alignment: .lastTextBaseline) {
                        let elemCount = elements.count
                        HStack(spacing: 0) {
                            NavigationLink {
                                ProfileView(profileLink: elements[2])
                            } label: {
                                Text(elements[1])
                                //                                .font(.title3)
                                //                                .bold()
                                //                                .scaledToFit()
                                //                                .minimumScaleFactor(0.5)
                                //                                .fixedSize(horizontal: false, vertical: true)
                                //                                .lineLimit(1)
                            }
                            if elemCount > 12 {
                                HStack(spacing: 0) {
                                    Text(" / ")
                                    //                                    .font(.title3)
                                    //                                    .bold()
                                    //                                    .scaledToFit()
                                    //                                    .minimumScaleFactor(0.5)
                                    //                                    .fixedSize(horizontal: false, vertical: true)
                                    //                                    .lineLimit(1)
                                    NavigationLink {
                                        ProfileView(profileLink: elements[10])
                                    } label: {
                                        Text(elements[9])
                                        //                                        .font(.title3)
                                        //                                        .bold()
                                        //                                        .scaledToFit()
                                        //                                        .minimumScaleFactor(0.5)
                                        //                                        .fixedSize(horizontal: false, vertical: true)
                                        //                                        .lineLimit(1)
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
                        
                        (elemCount > 12
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
        .onTapGesture {
            print(elements[3])
        }
    }
}
