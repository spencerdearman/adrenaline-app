//
//  DiveMeetsConnectorView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//

import SwiftUI

struct DiveMeetsConnectorView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.updateUserField) private var updateUserField
    @Environment(\.dropUser) private var dropUser
    @Binding var searchSubmitted: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var signupData: SignupData
    @State private var parsedLinks: DiverProfileRecords = [:]
    @State private var dmSearchSubmitted: Bool = false
    @State private var linksParsed: Bool = false
    @State private var personTimedOut: Bool = false
    @State private var diveMeetsID: String = ""
    @Binding var showSplash: Bool
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if searchSubmitted && !personTimedOut {
                SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                               parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted,
                               linksParsed: $linksParsed, timedOut: $personTimedOut)
            }
            if linksParsed || personTimedOut {
                ZStack() {
                    IsThisYouView(records: $parsedLinks, signupData: $signupData,
                                  diveMeetsID: $diveMeetsID, showSplash: $showSplash)
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
                updateUserField(email, "diveMeetsID", diveMeetsID)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // If user backs up into BasicInfoView, it drops them from db so they can be
                    // added again if they fill out the information and proceed
                    if let email = signupData.email {
                        dropUser(email)
                    }
                    dismiss()
                }) {
                    NavigationViewBackButton()
                }
            }
        }
    }
}

struct IsThisYouView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.updateUserField) private var updateUserField
    @Environment(\.getUser) private var getUser
    @State var sortedRecords: [(String, String)] = []
    @State var loginSuccessful: Bool = false
    @Binding var records: DiverProfileRecords
    @Binding var signupData: SignupData
    @Binding var diveMeetsID: String
    @Binding var showSplash: Bool
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
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
                    .font(.title).fontWeight(.semibold)
            } else if sortedRecords.count > 1 {
                Text("Are you one of these profiles?")
                    .font(.title).fontWeight(.semibold)
            } else {
                VStack(alignment: .center) {
                    Spacer()
                    Text("No DiveMeets Profile Found")
                        .font(.title).fontWeight(.semibold)
                    NavigationLink(destination: signupData.accountType == .athlete
                                   ? AnyView(AthleteRecruitingView(signupData: $signupData,
                                                                   diveMeetsID: $diveMeetsID,
                                                                   showSplash: $showSplash))
                                   : AnyView(AdrenalineProfileView(
                                    userEmail: signupData.email ?? "",
                                    loginSuccessful: $loginSuccessful))) {
                                        ZStack {
                                            Rectangle()
                                                .foregroundColor(Custom.darkGray)
                                                .frame(width: screenWidth * 0.2,
                                                       height: screenWidth * 0.9)
                                                .mask(RoundedRectangle(cornerRadius: 50))
                                                .shadow(radius: 6)
                                            Text("Next")
                                                .foregroundColor(.primary)
                                        }
                    }
                    Spacer()
                }
                .simultaneousGesture(TapGesture().onEnded({
                    withAnimation {
                        showSplash = false
                    }
                }))
            }
            if sortedRecords.count >= 1 {
                ScrollView {
                    ForEach(sortedRecords, id: \.1) { record in
                        let (key, value) = record
                        
                        NavigationLink(destination: signupData.accountType == .athlete
                                       ? AnyView(AthleteRecruitingView(signupData: $signupData,
                                                                       diveMeetsID: $diveMeetsID,
                                                                       showSplash: $showSplash))
                                       : AnyView(AdrenalineProfileView(
                                        userEmail: signupData.email ?? "",
                                        loginSuccessful: $loginSuccessful))) {
                                            HStack {
                                                Spacer()
                                                ProfileImage(
                                                    diverID: String(value
                                                        .components(separatedBy: "=").last ?? ""))
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
                                            diveMeetsID =
                                            String(value.components(separatedBy: "=").last ?? "")
                                            guard let email = signupData.email else { return }
                                            updateUserField(email, "diveMeetsID", diveMeetsID)
                                            
                                            if signupData.accountType != .athlete {
                                                withAnimation {
                                                    showSplash = false
                                                }
                                            }
                                        })
                                        .shadow(radius: 5)
                                        .padding([.leading, .trailing])
                    }
                    .padding()
                    NavigationLink {
                        signupData.accountType == .athlete
                                       ? AnyView(AthleteRecruitingView(signupData: $signupData,
                                                                       diveMeetsID: $diveMeetsID,
                                                                       showSplash: $showSplash))
                                       : AnyView(AdrenalineProfileView(
                                        userEmail: signupData.email ?? "",
                                        loginSuccessful: $loginSuccessful))
                    } label: {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Custom.darkGray)
                                .frame(width: screenWidth * 0.2, height: screenWidth * 0.9)
                                .mask(RoundedRectangle(cornerRadius: 50))
                                .shadow(radius: 6)
                            Text("Next")
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            sortedRecords = getSortedRecords(records)
            blockingNetwork = false
        }
    }
}
