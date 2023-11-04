//
//  FinishedLiveResultsView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/10/23.
//

import SwiftUI
import SwiftSoup
import Amplify

struct FinishedLiveResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var currentMode
    @State private var html: String = ""
    @State private var elements: [[String]]?
    @State private var eventTitle: String?
    @State private var finishedParsing: Bool = false
    @State private var timedOut: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private let parser = FinishedLiveResultsParser()
    private let getTextModel = GetTextAsyncModel()
    
    var link: String
    
    
    
    var body: some View {
        ZStack {
            LRWebView(request: link, html: $html)
            
            currentMode == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea()
            
            if finishedParsing, !timedOut, let eventTitle = eventTitle,
               let elements = elements {
                VStack {
                    Text(eventTitle)
                        .font(.title)
                        .bold()
                        .padding()
                        .multilineTextAlignment(.center)
                    Divider()
                    ScalingScrollView(records: elements, bgColor: .clear, rowSpacing: 50, 
                                      shadowRadius: 3) { (elem) in
                        LivePersonBubbleView(elements: elem)
                    }
                    .padding(.bottom, maxHeightOffset)
                }
            } else if timedOut {
                BackgroundBubble() {
                    Text("Unable to get live results, network timed out")
                        .padding()
                }
            } else {
                BackgroundBubble() {
                    VStack {
                        Text("Getting live results...")
                        ProgressView()
                    }
                    .padding()
                }
            }
        }
        .onChange(of: html) {
                Task {
                    let parseTask = Task {
                        await parser.getFinishedLiveResultsRecords(html: html)
                        elements = parser.resultsRecords
                        eventTitle = parser.eventTitle
                        // Resets both bools in each Task since this will run as html changes
                        finishedParsing = true
                        timedOut = false
                    }
                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: UInt64(timeoutInterval) * NSEC_PER_SEC)
                        parseTask.cancel()
                        // Resets both bools in each Task since this will run as html changes
                        finishedParsing = false
                        timedOut = true
                    }
                    
                    await parseTask.value
                    timeoutTask.cancel()
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

struct LivePersonBubbleView: View {
    @Environment(\.colorScheme) var currentMode
    var elements: [String]
    @State private var diverNewUser: NewUser? = nil
    @State private var synchroNewUser: NewUser? = nil
    
    // place, first, last, link, team, score, scoreLink, eventAvgScore, avgRoundScore
    // (synchroFirst, synchroLast, synchroLink, synchroTeam)
    
    var body: some View {
        let isSynchro = elements.count == 13
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .foregroundColor(Custom.darkGray)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(alignment: .firstTextBaseline) {
                        if let diver = diverNewUser {
                            NavigationLink(destination: AdrenalineProfileView(newUser: diver)) {
                                VStack(alignment: .leading) {
                                    Text(elements[1])
                                    Text(elements[2])
                                }
                                .scaledToFit()
                                .dynamicTypeSize(.xSmall ... .xLarge)
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text(elements[1])
                                Text(elements[2])
                            }
                            .scaledToFit()
                            .dynamicTypeSize(.xSmall ... .xLarge)
                        }
                        
                        if isSynchro {
                            Text("/")
                            if let diver = synchroNewUser {
                                NavigationLink(destination: AdrenalineProfileView(newUser: diver)) {
                                    VStack(alignment: .leading) {
                                        Text(elements[9])
                                        Text(elements[10])
                                    }
                                    .scaledToFit()
                                    .dynamicTypeSize(.xSmall ... .xLarge)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text(elements[9])
                                    Text(elements[10])
                                }
                                .scaledToFit()
                                .dynamicTypeSize(.xSmall ... .xLarge)
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.semibold)
                    // If we link to the results sheet in the future, elements[6] is the link
                    ZStack {
                        Rectangle()
                            .foregroundColor(Custom.accentThinMaterial)
                            .mask(RoundedRectangle(cornerRadius: 60, style: .continuous))
                            .shadow(radius: 2)
                            .frame(width: 200, height: 40)
                        // Score Link is elements[6]
                        Text("Score: " + elements[5])
                            .fontWeight(.semibold)
                            .scaledToFit()
                    }
                }
                
                HStack {
                    Text("Place: " + elements[0])
                        .fontWeight(.semibold)
                    Spacer()
                    HStack {
                        Text(elements[4])
                            
                        if isSynchro {
                            Text("/")
                            Text(elements[12])
                        }
                    }
                    .foregroundColor(.gray)
                    .font(.title3)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Event Avg Score: " + elements[7])
                            .font(.footnote.weight(.semibold))
                        Text("Avg Round Score: " + elements[8])
                            .font(.footnote.weight(.semibold))
                    }
                }
            }
            .padding(20)
            .onAppear {
                Task {
                    guard let diveMeetsId = elements[3].split(separator: "=").last else { return }
                    let pred = NewUser.keys.diveMeetsID == String(diveMeetsId)
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        diverNewUser = users[0]
                    }
                    
                    if isSynchro {
                        guard let diveMeetsId = elements[11].split(separator: "=").last else { return }
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
}
