//
//  LoginProfile.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 4/27/23.
//

import SwiftUI



extension String {
    func slice(from: String, to: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
        return String(self[rangeFrom..<rangeTo])
    }
    
    func slice(from: String) -> String? {
        guard let rangeFrom = range(of: from)?.upperBound else { return nil }
        return String(self[rangeFrom...])
    }
    
    func slice(to: String) -> String? {
        guard let rangeTo = self.range(of: to)?.lowerBound else { return nil }
        return String(self[..<rangeTo])
    }
}

func fixPlacement(data: [[String]] ) -> [[String]] {
    var updated = data
    updated[0] = updated[0][0].components(separatedBy: "History")
    updated[0].remove(at: 1)
    return data
}

struct LoginProfile: View {
    var profileLink: String
    var diverID : String
    @Binding var loggedIn: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var loginSearchSubmitted: Bool
    @State var diverData : [[String]] = []
    @StateObject private var parser = ProfileParser()
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    
    private var profileType: String {
        parser.profileData.coachDivers == nil ? "Diver" : "Coach"
    }
    
    
    init(link: String, diverID: String = "00000", loggedIn: Binding<Bool>,
         divemeetsID: Binding<String>, password: Binding<String>, searchSubmitted: Binding<Bool>,
         loginSuccessful: Binding<Bool>, loginSearchSubmitted: Binding<Bool>) {
        self.profileLink = link
        self.diverID = diverID
        self._loggedIn = loggedIn
        self._divemeetsID = divemeetsID
        self._password = password
        self._searchSubmitted = searchSubmitted
        self._loginSuccessful = loginSuccessful
        self._loginSearchSubmitted = loginSearchSubmitted
    }
    
    var body: some View {
        ProfileView(profileLink: profileLink, isLoginProfile: true)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Logout", action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        loggedIn = false // add this
                        divemeetsID = ""
                        password = ""
                        searchSubmitted = false
                        loginSuccessful = false
                        loginSearchSubmitted = false
                        searchSubmitted = false
                    }
                })
                .buttonStyle(.bordered)
                .cornerRadius(30)
            }
        }
    }
}

struct WhiteDivider: View{
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.white)
            .padding([.leading, .trailing], 3)
    }
}
