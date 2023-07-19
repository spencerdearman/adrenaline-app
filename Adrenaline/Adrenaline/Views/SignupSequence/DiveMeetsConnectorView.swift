//
//  DiveMeetsConnectorView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//

import SwiftUI

struct DiveMeetsConnectorView: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var searchSubmitted: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var signupData: SignupData
    @Binding var selectedOption: AccountType?
    @State var parsedLinks: DiverProfileRecords = [:]
    @State var dmSearchSubmitted: Bool = false
    @State var linksParsed: Bool = false
    @State var personTimedOut: Bool = false
    @State var diveMeetsID: String = ""
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
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
                    IsThisYouView(records: $parsedLinks, signupData: $signupData, selectedOption: $selectedOption, diveMeetsID: $diveMeetsID)
                }
            } else {
                ZStack{
                    bgColor.ignoresSafeArea()
                    VStack {
                        Text("Searching")
                        ProgressView()
                    }
                }
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var currentMode
    @Binding var records: DiverProfileRecords
    @Binding var signupData: SignupData
    @Binding var selectedOption: AccountType?
    @Binding var diveMeetsID: String
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
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
        bgColor.ignoresSafeArea()
        VStack {
            Spacer()
            Text("Is this you?")
                .font(.title).fontWeight(.semibold)
            ForEach(getSortedRecords(records), id: \.1) { record in
                let (key, value) = record
                NavigationLink(destination: AdrenalineProfileView(diveMeetsID: $diveMeetsID, signupData: $signupData, selectedOption: $selectedOption)) {
                    HStack {
                        Spacer()
                        ProfileImage(diverID: String(value.components(separatedBy: "=").last ?? ""))
                            .scaleEffect(0.4)
                            .frame(width: 100, height: 100)
                        Text(key)
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                            .padding()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.gray)
                            .padding()
                        
                    }
                    .background(Custom.darkGray)
                    .cornerRadius(50)
                }
                .simultaneousGesture(TapGesture().onEnded{
                    diveMeetsID = String(value.components(separatedBy: "=").last ?? "")
                })
                .shadow(radius: 5)
                .padding([.leading, .trailing])
            }
            Spacer()
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
