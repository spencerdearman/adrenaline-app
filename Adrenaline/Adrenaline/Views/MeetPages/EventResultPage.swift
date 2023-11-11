//
//  EventResultPage.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/26/23.
//

import SwiftUI

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
//                    ScalingScrollView(records: resultData, bgColor: .clear, rowSpacing: 10,
//                                      shadowRadius: 8) { (elem) in
//                        PersonBubbleView(elements: elem, eventTitle: eventTitle)
//                    }
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
