//
//  DiveMeetsConnectorView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//

import SwiftUI

struct DiveMeetsConnectorView: View {
    @Binding var searchSubmitted: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @State var parsedLinks: DiverProfileRecords = [:]
    @State var dmSearchSubmitted: Bool = false
    @State var linksParsed: Bool = false
    @State var personTimedOut: Bool = false
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if searchSubmitted {
                SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                               parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted,
                               linksParsed: $linksParsed, timedOut: $personTimedOut)
            }
            if linksParsed {
                ZStack (alignment: .topLeading) {
                    IsThisYouView(records: $parsedLinks)
                }
            } else {
                Text("No DiveMeets Profile Found")
            }
        }
        .ignoresSafeArea(.keyboard)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .onDisappear {
            searchSubmitted = false
        }
        
    }
}

struct IsThisYouView: View {
    @Binding var records: DiverProfileRecords
    
    // Converts keys and lists of values into tuples of key and value
    private func getSortedRecords(_ records: DiverProfileRecords) -> [(String, String)] {
        var result: [(String, String)] = []
        for (key, value) in records {
            for link in value {
                result.append((key, link))
            }
        }
        
        return result.sorted(by: { $0.0 < $1.0 })
    }
    
    var body: some View {
        ForEach(getSortedRecords(records), id: \.1) { record in
            let (key, value) = record
            NavigationLink(destination: ProfileView(profileLink: value)) {
                HStack {
                    Text(key)
                        .foregroundColor(.primary)
                        .font(.title3)
                        .padding()
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.gray)
                        .padding()
                }
                .background(Custom.darkGray)
                .cornerRadius(30)
            }
            .shadow(radius: 5)
            .padding([.leading, .trailing])
        }
    }
}
