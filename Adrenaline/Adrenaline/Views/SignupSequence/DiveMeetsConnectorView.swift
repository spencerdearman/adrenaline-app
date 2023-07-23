//
//  DiveMeetsConnectorView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//

import SwiftUI

struct DiveMeetsConnectorView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.modelDB) var db
    @Binding var searchSubmitted: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var signupData: SignupData
    @State private var parsedLinks: DiverProfileRecords = [:]
    @State private var dmSearchSubmitted: Bool = false
    @State private var linksParsed: Bool = false
    @State private var personTimedOut: Bool = false
    @State private var diveMeetsID: String = ""
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
                    IsThisYouView(records: $parsedLinks, signupData: $signupData, diveMeetsID: $diveMeetsID)
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
            if diveMeetsID != "", let email = signupData.email {
                db.updateUserField(email: email, key: "diveMeetsID", value: diveMeetsID)
            }
        }
        
    }
}

struct IsThisYouView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var currentMode
    @State var sortedRecords: [(String, String)] = []
    @Binding var records: DiverProfileRecords
    @Binding var signupData: SignupData
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
            if sortedRecords.count == 1 {
                Text("Is this you?")
                    .onAppear {
                        print(String(records.values.count))
                    }
                    .font(.title).fontWeight(.semibold)
            } else if sortedRecords.count > 1 {
                Text("Are you one of these profiles?")
                    .font(.title).fontWeight(.semibold)
            } else {
                Text("No DiveMeets Profile Found")
                    .font(.title).fontWeight(.semibold)
                NavigationLink {
                    AdrenalineProfileView(diveMeetsID: $diveMeetsID, signupData: $signupData)
                } label: {
                    BackgroundBubble() {
                        Text("Next")
                    }
                }
            }
            ForEach(sortedRecords, id: \.1) { record in
                let (key, value) = record
                
                NavigationLink(destination: signupData.accountType == .athlete
                               ? AnyView(AthleteRecruitingView(signupData: $signupData, diveMeetsID: $diveMeetsID))
                               : AnyView(ProfileView(profileLink: ""))) {
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
        .onAppear{
            sortedRecords = getSortedRecords(records)
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
