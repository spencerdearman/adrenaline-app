//
//  EntryPageView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/2/23.
//

import SwiftUI

struct EntryPageView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    var entriesLink: String
    @State var entries: [EventEntry]?
    @ObservedObject var ep: EntriesParser = EntriesParser()
    private let getTextModel = GetTextAsyncModel()
    private var grayColor: Color {
        currentMode == .light
        ? Color(red: 0.9, green: 0.9, blue: 0.9)
        : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        ZStack {
            if let entries = entries {
                bgColor.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(entries, id: \.self) { entry in
                            ZStack {
                                Rectangle()
                                    .fill(Custom.darkGray)
                                    .cornerRadius(30)
                                    .shadow(radius: 10)
                                EntryView(entry: entry) {
                                    if let partner = entry.synchroPartner {
                                        return HStack {
                                            VStack {
                                                NavigationLink(
                                                    destination: ProfileView(
                                                        profileLink: entry.link ?? ""),
                                                    label: {
                                                        Text((entry.lastName ?? "") + ", " +
                                                             (entry.firstName ?? ""))
                                                    })
                                                .font(.headline)
                                                .scaledToFit()
                                                
                                                Divider()
                                                
                                                NavigationLink(
                                                    destination: ProfileView(profileLink: partner.link),
                                                    label: {
                                                        Text(partner.lastName + ", " +
                                                             partner.firstName)
                                                    })
                                                .font(.headline)
                                                .scaledToFit()
                                            }
                                            .fixedSize(horizontal: true, vertical: false)
                                            
                                            Text(entry.team ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(Color.secondary)
                                                .scaledToFit()
                                                .lineLimit(1)
                                            
                                            Spacer()
                                        }
                                    } else {
                                        return HStack {
                                            NavigationLink(
                                                destination: ProfileView(profileLink: entry.link ?? ""),
                                                label: {
                                                    Text((entry.lastName ?? "") + ", " +
                                                         (entry.firstName ?? ""))
                                                })
                                            .font(.headline)
                                            .scaledToFit()
                                            
                                            Text(entry.team ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(Color.secondary)
                                                .scaledToFit()
                                            
                                            Spacer()
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .padding(10)
                }
            }
            else {
                VStack {
                    Text("Getting event entries...")
                    ProgressView()
                }
            }
        }
        .padding(.bottom, maxHeightOffset)
        .onAppear {
            Task {
                // Initialize meet parse from index page
                let url = URL(string: entriesLink)
                
                if let url = url {
                    // This sets getTextModel's text field equal to the HTML from url
                    await getTextModel.fetchText(url: url)
                    
                    if let html = getTextModel.text {
                        entries = try await ep.parseEntries(html: html)
                    }
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

struct EntryView: View {
    var entry: EventEntry
    var labelView: () -> any View
    @State var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading) {
                    Text(entry.board != nil ? "Board: " + entry.board! : "")
                    HStack(alignment: .top) {
                        VStack {
                            Text("Number")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(dive.number)
                            }
                        }
                        Spacer()
                        VStack {
                            Text("Height")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                // Converts Double to Int if it is a x.0 decimal (all but 7.5M)
                                floor(dive.height) == dive.height
                                ? Text(String(Int(dive.height)) + "M")
                                : Text(String(dive.height) + "M")
                            }
                        }
                        Spacer()
                        VStack {
                            Text("Name")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(dive.name)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        VStack {
                            Text("DD")
                                .bold()
                            ForEach(entry.dives ?? [], id: \.self) { dive in
                                Text(String(dive.dd))
                            }
                        }
                    }
                    
                    let diveNums = (entry.dives ?? []).map { $0.number }
                    NavigationLink(destination: MeetScoreCalculator(dives: diveNums)) {
                        Text("See in Meet Score Calculator")
                            .foregroundColor(.primary)
                            .padding([.leading, .trailing])
                            .padding([.top, .bottom], 5)
                            .background(RoundedRectangle(cornerRadius: 30).fill(Custom.specialGray))
                    }
                }
            },
            label: {
                AnyView(labelView())
            }
        )
    }
}
