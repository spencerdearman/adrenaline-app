//
//  Event.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 5/5/23.
//

import SwiftUI

struct Event: View {
    @Environment(\.dismiss) private var dismiss
    
    var isFirstNav: Bool
    var meet: MeetEvent
    @State var diverData : (String, String, String, Double, Double, Double, String) =
    ("", "", "", 0.0, 0.0, 0.0, "")
    @State var diverTableData: [Int: (String, String, String, Double, Double, Double, String)] = [:]
    @State var scoreDictionary: [String: String] = [:]
    @State var isExpanded: Bool = false
    @State var expandedIndices: Set<Int> = []
    @State var scoreString: String = ""
    @State var fullEventPageShown: Bool = false
    @State var finishedParsing: Bool = false
    @State var timedOut: Bool = false
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    @StateObject private var parser = EventHTMLParser()
    @StateObject private var scoreParser = ScoreHTMLParser()
    
    var body: some View {
        ZStack {
            if finishedParsing && !timedOut {
                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(meet.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        ZStack {
                            Rectangle()
                                .mask(RoundedRectangle(cornerRadius: 40))
                                .foregroundColor(Custom.darkGray)
                                .shadow(radius: 3)
                                .frame(width: screenWidth * 0.9, height: screenHeight * 0.18)
                            VStack {
                                Text("Dates: " + diverData.1)
                                Text("Organization: " + diverData.2)
                                    .multilineTextAlignment(.trailing)
                                WhiteDivider()
                                Text("Total Score: " + String(diverData.5))
                                    .font(.title3)
                                    .bold()
                                HStack{
                                    Text("Total Net Score: " + String(diverData.3))
                                    Text("Total DD: " + String(diverData.4))
                                }
                            }
                            .frame(width: screenWidth * 0.85)
                        }
                        if meet.firstNavigation && !fullEventPageShown {
                            NavigationLink (destination: {
                                EventResultPage(meetLink: diverData.6)
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(Custom.darkGray)
                                        .frame(width: screenWidth * 0.45, height: screenWidth * 0.1)
                                        .mask(RoundedRectangle(cornerRadius: 50))
                                        .shadow(radius: 6)
                                    Text("Full Event Page")
                                        .foregroundColor(.primary)
                                }
                            })
                        }
                    }
                    .padding([.top, .leading, .trailing])
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: -3) {
                            Text("Scores")
                                .font(.title2).fontWeight(.semibold)
                                .padding([.top, .bottom])
                            ForEach(diverTableData.sorted(by: { $0.key < $1.key }),
                                    id: \.key) { key, value in
                                ZStack {
                                    Rectangle()
                                        .fill(Custom.darkGray)
                                        .cornerRadius(30)
                                        .shadow(radius: 4)
                                        .frame(maxWidth: screenWidth * 0.9)
                                    DisclosureGroup(
                                        isExpanded: isExpanded(key),
                                        content: {
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Height: \(value.1)")
                                                Text("Scores: " + (scoreDictionary[value.0] ?? ""))
                                                Text("Name: \(value.2)")
                                                Text("Net Score: \(value.3, specifier: "%.2f")")
                                                Text("DD: \(value.4, specifier: "%.1f")")
                                            }
                                            .padding(.leading, 20)
                                        },
                                        label: {
                                            Text(value.0 + " - " + String(value.5))
                                                .font(.headline)
                                        }
                                    )
                                    .frame(maxWidth: screenWidth * 0.85)
                                    .padding()
                                    .foregroundColor(.primary)
                                }
                                .padding(.bottom)
                            }
                        }
                    }
                    .frame(height: 420)
                    .padding()
                    .background(Color.clear)
                    .ignoresSafeArea()
                }
                .padding(.bottom, maxHeightOffset)
            } else if timedOut {
                BackgroundBubble() {
                    Text("Unable to get event data, network timed out")
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            } else {
                BackgroundBubble() {
                    VStack {
                        Text("Getting event data...")
                        ProgressView()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                let parseTask = Task {
                    if let link = meet.link, !finishedParsing {
                        await parser.eventParse(urlString: link)
                        diverData = parser.eventData
                        await parser.tableDataParse(urlString: link)
                        diverTableData = parser.diveTableData
                        
                        for (_, value) in diverTableData.sorted(by: { $0.key < $1.key }) {
                            scoreDictionary[value.0] = await scoreParser.parse(urlString: value.6)
                        }
                        
                        finishedParsing = true
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
        }
    }
    
    private func isExpanded(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { expandedIndices.contains(index) },
            set: { isExpanded in
                if isExpanded {
                    expandedIndices.insert(index)
                } else {
                    expandedIndices.remove(index)
                }
            }
        )
    }
}
