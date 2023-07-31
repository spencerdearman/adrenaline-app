//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct AdrenalineProfileView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.getUser) private var getUser
    @Environment(\.getAthlete) private var getAthlete
    var firstSignIn: Bool = false
    var showBackButton: Bool = false
    @State private var offSet: CGFloat = 0
    @State var athlete: Athlete = Athlete()
    @Binding var user: User
    @Binding var loginSuccessful: Bool
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    func formatLocationString(_ input: String) -> String {
        var formattedString = input
        
        if let spaceIndex = input.lastIndex(of: " ") {
            formattedString.insert(",", at: spaceIndex)
        }
        if formattedString.count >= 2 {
            let lastTwo = formattedString.suffix(2).uppercased()
            formattedString.replaceSubrange(formattedString.index(formattedString.endIndex, offsetBy: -2)..<formattedString.endIndex, with: lastTwo)
        }
        return formattedString
    }
    
    var body: some View {
        ZStack {
            // Universal Base View
            if !loginSuccessful {
                BackgroundSpheres()
                    .ignoresSafeArea()
            }
            VStack {
                ProfileImage(diverID: (user.diveMeetsID ?? ""))
                    .frame(width: 200, height: 150)
                    .scaleEffect(0.9)
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .onAppear {
                        offSet = screenHeight * 0.45
                    }
                VStack {
                    BackgroundBubble(vPadding: 20, hPadding: 60) {
                        VStack() {
                            HStack (alignment: .firstTextBaseline) {
                                Text((user.firstName ?? "") + " " + (user.lastName
                                                                     ?? "")) .font(.title3).fontWeight(.semibold)
                                Text(user.accountType ?? "")
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                            HStack (alignment: .firstTextBaseline) {
                                if user.accountType == "Athlete" {
                                    let a = getAthlete(user.email ?? "")
                                    HStack {
                                        Image(systemName: "mappin.and.ellipse")
                                        if let hometown = a?.hometown, !hometown.isEmpty {
                                            Text(formatLocationString(hometown))
                                        } else {
                                            Text("?")
                                        }
                                    }
                                    HStack {
                                        Image(systemName: "person.fill")
                                        if let age = a?.age {
                                            Text(String(age))
                                        } else {
                                            Text("?")
                                        }
                                    }
                                }
                                if user.diveMeetsID != "" {
                                    HStack {
                                        Image(systemName: "figure.pool.swim")
                                        if let diveMeetsID = user.diveMeetsID {
                                            Text(diveMeetsID)
                                        } else {
                                            Text("?")
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: screenWidth * 0.8)
                    }
                }
            }
            .offset(y: -screenHeight * 0.3)
            .padding([.leading, .trailing, .top])
            .frame(width: screenWidth * 0.9)
            .overlay{
                if loginSuccessful {
                    BackgroundBubble(vPadding: 20, hPadding: 35) {
                        Text("Logout")
                            .onTapGesture{
                                withAnimation {
                                    loginSuccessful = false
                                }
                            }
                    }
                    .offset(x: -screenWidth * 0.35, y: -screenHeight * 0.42)
                }
                BackgroundBubble() {
                    NavigationLink {
                        SettingsPage(user: $user)
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                }
                .offset(x: screenWidth * 0.26, y: -screenHeight * 0.3)
                .scaleEffect(1.4)
            }
            .offset(y: firstSignIn ? -screenHeight * 0.14 : -screenHeight * 0.25)
            ZStack {
                Rectangle()
                    .foregroundColor(bgColor)
                    .cornerRadius(50)
                    .shadow(radius: 10)
                    .frame(width: screenWidth, height: screenHeight * 1.05)
                VStack {
                    if let type = user.accountType {
                        if type == AccountType.athlete.rawValue {
                            DiverView(user: $user)
                        } else if type == AccountType.coach.rawValue {
                            CoachView(user: $user)
                        } else if type == AccountType.spectator.rawValue {
                            Text("This is a spectator profile")
                        } else {
                            Text("The account type has not been specified")
                        }
                    } else {
                        Text("Account type not selected")
                    }
                }
            }
            .offset(y: offSet)
            .onSwipeGesture(trigger: .onEnded) { direction in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if direction == .up {
                        offSet = screenHeight * 0.13
                    } else if direction == .down {
                        offSet = screenHeight * 0.45
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if showBackButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        NavigationViewBackButton()
                    }
                }
            }
        }
    }
}

struct SettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    @State var email: String = ""
    @State var password: String = ""
    @State var phoneNumber: String = ""
    @Binding var user: User
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    var body: some View {
        Text("Settings Page")
    }
    //    var body: some View {
    //        ScrollView {
    //            VStack {
    //                Group {
    //                    BackgroundBubble(vPadding: 20, hPadding: 20) {
    //                        Text("Settings").font(.title2).fontWeight(.semibold)
    //                    }
    //                    ProfileImage(diverID: user.diveMeetsID)
    //                        .scaleEffect(0.75)
    //                        .frame(width: 150, height: 160)
    //                    Text((user.firstName ?? "") + " " + (user.lastName ?? ""))
    //                        .font(.title3).fontWeight(.semibold)
    //                    Text(user.email ?? "")
    //                        .foregroundColor(.secondary)
    //                    if let phoneNum = user.phone {
    //                        Text(phoneNum)
    //                            .foregroundColor(.secondary)
    //                    }
    //                }
    //                Group {
    //                    NavigationLink {
    //                        EditProfile()
    //                    } label: {
    //                        HStack {
    //                            BackgroundBubble(color: Custom.coolBlue, vPadding: 20, hPadding: 20) {
    //                                HStack {
    //                                    Text("Edit Profile")
    //                                        .foregroundColor(.white)
    //                                        .fontWeight(.semibold)
    //                                    Image(systemName: "chevron.right")
    //                                        .foregroundColor(.white)
    //                                }
    //                            }
    //                        }
    //                    }
    //                }
    ////                Group {
    ////                    Text("Profile Information")
    ////                    Divider()
    ////                    Text("Update Email")
    ////                    TextField("Email", text: $email)
    ////                        .autocapitalization(.none)
    ////                        .textFieldStyle(.roundedBorder)
    ////                        .frame(width: textFieldWidth)
    ////                        .textContentType(.emailAddress)
    ////                        .keyboardType(.emailAddress)
    //////                        .onChange(of: email) { _ in
    //////                            user.email = email
    //////                        }
    ////                    Text("Update Password")
    ////                    //NEED PASSWORD FIELD
    ////                    Text("Update Phone Number")
    ////                    TextField("Phone", text: $phoneNumber)
    ////                        .textFieldStyle(.roundedBorder)
    ////                        .textContentType(.telephoneNumber)
    ////                        .keyboardType(.numberPad)
    ////                        .frame(width: textFieldWidth)
    //////                        .onChange(of: phoneNumber) { _ in
    //////                            user.phone = phoneNumber
    //////                        }
    ////                    Divider()
    ////                    Text("Preferences")
    ////                    Divider()
    ////                }
    //            }
    //        }
    //        .navigationBarBackButtonHidden(true)
    //        .toolbar {
    //            ToolbarItem(placement: .navigationBarLeading) {
    //                Button(action: { dismiss() }) {
    //                    NavigationViewBackButton()
    //                }
    //            }
    //        }
    //    }
}

struct EditProfile: View {
    var body: some View {
        Text("This is where you will edit your account")
    }
}


struct DiveMeetsLink: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var user: User
    @State var diveMeetsID: String = ""
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    var body: some View {
        VStack {
            BackgroundBubble(vPadding: 40, hPadding: 40) {
                VStack {
                    Text("Please Enter DiveMeets ID")
                        .foregroundColor(.primary)
                        .font(.title2).fontWeight(.semibold)
                    TextField("DiveMeets ID", text: $diveMeetsID)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: diveMeetsID) { _ in
                            user.diveMeetsID = diveMeetsID
                        }
                    .frame(width: textFieldWidth) }
            }
            BackgroundBubble(onTapGesture: { presentationMode.wrappedValue.dismiss() }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct BackgroundSpheres: View {
    @State var width: CGFloat = 0
    @State var height: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack{}
                .onAppear {
                    width = geometry.size.width
                    height = geometry.size.height
                }
            VStack {
                ZStack {
                    Circle()
                    // Circle color
                        .fill(Custom.darkBlue)
                    // Adjust the size of the circle as desired
                        .frame(width: geometry.size.width * 2.5,
                               height: geometry.size.width * 2.5)
                    // Center the circle
                        .position(x: geometry.size.width, y: -geometry.size.width * 0.55)
                        .shadow(radius: 15)
                        .frame(height: geometry.size.height * 0.7)
                        .clipped().ignoresSafeArea()
                        .ignoresSafeArea()
                    Circle()
                        .fill(Custom.coolBlue) // Circle color
                        .frame(width:geometry.size.width * 1.3, height:geometry.size.width * 1.3)
                        .position(x: geometry.size.width, y: geometry.size.width * 0.7)
                        .shadow(radius: 15)
                        .frame(height: geometry.size.height * 0.7)
                        .clipped().ignoresSafeArea()
                        .ignoresSafeArea()
                    Circle()
                        .fill(Custom.medBlue) // Circle color
                        .frame(width: geometry.size.width * 1.1, height: geometry.size.width * 1.1)
                        .position(x: 0, y: geometry.size.width * 0.7)
                        .shadow(radius: 15)
                        .frame(height: geometry.size.height * 0.7)
                        .clipped().ignoresSafeArea()
                        .ignoresSafeArea()
                }
            }
        }
    }
}
