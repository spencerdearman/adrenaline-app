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
    @State var profileType : String = ""
    @StateObject private var parser = HTMLParser()
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    
    private var diverDataInBounds: Bool {
        diverData.count > 0 && diverData[0].count > 0
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
        Group {
            if profileType == "Diver" {
                ZStack {
                    VStack {
                        VStack {
                            ZStack {
                                Button("Logout", action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        loggedIn = false // add this
                                        divemeetsID = ""
                                        password = ""
                                        searchSubmitted = false
                                        loginSuccessful = false
                                        loginSearchSubmitted = false
                                        diverData = []
                                        profileType = ""
                                        searchSubmitted = false
                                    }
                                })
                                .buttonStyle(.bordered)
                                .cornerRadius(30)
                                .offset(x: -screenWidth * 0.33, y: -screenHeight * 0.23)
                                ProfileImage(diverID: diverID)
                                    .offset(y:-100)
                            }
                            VStack {
                                VStack(alignment: .leading) {
                                    HStack (alignment: .firstTextBaseline) {
                                        if diverDataInBounds {
                                            let firstName = diverData[0][0]
                                                .slice(from: "Name: ", to: " ") ?? ""
                                            let lastName = diverData[0][0]
                                                .slice(from: firstName + " ", to: " ") ?? ""
                                            
                                            Text(firstName + " " + lastName)
                                                .font(.title)
                                                .foregroundColor(.white)
                                        } else {
                                            Text("")
                                        }
                                        
                                        Text(diverID)
                                            .font(.subheadline)
                                            .foregroundColor(Custom.secondaryColor)
                                    }
                                    WhiteDivider()
                                    HStack (alignment: .firstTextBaseline) {
                                        Image(systemName: "house.fill")
                                        diverDataInBounds
                                        ? Text(
                                            (diverData[0][0].slice(from: "State: ",
                                                                   to: " Country")  ?? "")
                                            + ", "
                                            + (diverData[0][0].slice(from: " Country: ",
                                                                     to: " Gender") ?? ""))
                                        : Text("")
                                    }
                                    .font(.subheadline).foregroundColor(.white)
                                    HStack (alignment: .firstTextBaseline) {
                                        Image(systemName: "person.circle")
                                        diverDataInBounds
                                        ? Text("Gender: " +
                                               (diverData[0][0].slice(from: " Gender: ",
                                                                      to: " Age") ?? ""))
                                        : Text("")
                                        diverDataInBounds
                                        ? Text("Age: " +
                                               (diverData[0][0].slice(from: " Age: ",
                                                                      to: " FINA") ?? ""))
                                        : Text("")
                                        diverDataInBounds
                                        ? Text("FINA Age: " +
                                               (diverData[0][0].slice(from: " FINA Age: ",
                                                                      to: "DiveMeets") ?? "")
                                                .prefix(2))
                                        : Text("")
                                    }
                                    .font(.subheadline).foregroundColor(.white)
                                    .padding([.leading], 2)
                                }
                                .offset(y:-150)
                            }
                            .padding()
                            
                        }
                        MeetList(profileLink: profileLink)
                            .offset(y: -160)
                    }
                }
                
            } else {
                VStack {
                    VStack {
                        ProfileImage(diverID: diverID)
                            .offset(y:-100)
                        VStack{
                            VStack(alignment: .leading) {
                                HStack (alignment: .firstTextBaseline){
                                    diverDataInBounds
                                    ? Text(diverData[0][0].slice(from: "Name: ",
                                                                 to: " City/State") ?? "")
                                    .font(.title)
                                    : Text("")
                                    
                                    Text(diverID)
                                        .font(.subheadline).foregroundColor(Custom.secondaryColor)
                                }
                                Divider()
                                HStack (alignment: .firstTextBaseline){
                                    Image(systemName: "house.fill")
                                    diverDataInBounds
                                    ? Text(
                                        (diverData[0][0].slice(from: " City/State: ",
                                                               to: " Country")  ?? "")
                                        + ", "
                                        + (diverData[0][0].slice(from: " Country: ",
                                                                 to: " Gender") ?? ""))
                                    : Text("")
                                }
                                .font(.subheadline)
                                HStack (alignment: .firstTextBaseline) {
                                    Image(systemName: "person.circle")
                                    diverDataInBounds
                                    ? Text("Gender: " + (diverData[0][0]
                                        .slice(from: " Gender: ", to: " DiveMeets") ?? ""))
                                    : Text("")
                                }
                                .font(.subheadline)
                                .padding([.leading], 2)
                                Divider()
                            }
                            .offset(y:-150)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await parser.parse(urlString: profileLink)
                diverData = parser.myData
                if diverDataInBounds {
                    let divers = diverData[0][0].slice(from: "Divers:", to: "Judging") ?? ""
                    
                    if divers != "" {
                        profileType = "Coach"
                    } else {
                        profileType = "Diver"
                    }
                }
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
