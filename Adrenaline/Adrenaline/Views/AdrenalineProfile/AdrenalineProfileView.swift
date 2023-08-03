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
    var userEmail: String
    @State private var offset: CGFloat = 0
    @State var user: User?
    @State var userViewData: UserViewData = UserViewData()
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
            formattedString.replaceSubrange(
                formattedString.index(formattedString.endIndex,
                                      offsetBy: -2)..<formattedString.endIndex, with: lastTwo)
        }
        return formattedString
    }
    
    var body: some View {
        ZStack {
            if let user = user {
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
                            offset = screenHeight * 0.45
                        }
                    PersonalInfoView(userViewData: $userViewData)
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
                            SettingsPage(userViewData: $userViewData)
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                    }
                    .offset(x: screenWidth * 0.26, y: -screenHeight * 0.3)
                    .scaleEffect(1.4)
                }
                ZStack{
                    Rectangle()
                        .foregroundColor(Custom.darkGray)
                        .cornerRadius(50)
                        .shadow(radius: 10)
                        .frame(width: screenWidth, height: screenHeight * 1.05)
                    VStack {
                        if let type = user.accountType {
                            if type == AccountType.athlete.rawValue {
                                DiverView(userViewData: $userViewData)
                            } else if type == AccountType.coach.rawValue {
                                CoachView(userViewData: $userViewData)
                            } else if type == AccountType.spectator.rawValue {
                                Text("This is a spectator profile")
                            } else {
                                Text("The account type has not been specified")
                            }
                        }
                    }
                }
                .offset(y: offset)
                .onSwipeGesture(trigger: .onEnded) { direction in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if direction == .up {
                            offset = screenHeight * 0.13
                        } else if direction == .down {
                            offset = screenHeight * 0.45
                        }
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
        .onAppear {
            guard let storedUser = getUser(userEmail) else { return }
            user = storedUser
            userViewData = userEntityToViewData(user: storedUser)
        }
    }
}

struct PersonalInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.getUser) var getUser
    @Environment(\.getAthlete) var getAthlete
    @Binding var userViewData: UserViewData
    
    private let screenWidth = UIScreen.main.bounds.width
    
    func formatLocationString(_ input: String) -> String {
        var formattedString = input
        
        if let spaceIndex = input.lastIndex(of: " ") {
            formattedString.insert(",", at: spaceIndex)
        }
        if formattedString.count >= 2 {
            let lastTwo = formattedString.suffix(2).uppercased()
            formattedString.replaceSubrange(
                formattedString.index(formattedString.endIndex,
                                      offsetBy: -2)..<formattedString.endIndex, with: lastTwo)
        }
        return formattedString
    }
    
    var body: some View {
        VStack {
            BackgroundBubble(vPadding: 20, hPadding: 60) {
                VStack {
                    HStack (alignment: .firstTextBaseline) {
                        Text((userViewData.firstName ?? "") + " " +
                             (userViewData.lastName ?? "")).font(.title3).fontWeight(.semibold)
                        Text(userViewData.accountType ?? "")
                            .foregroundColor(.secondary)
                    }
                    if userViewData.accountType != "Spectator" {
                        if currentMode == .light {
                            Divider()
                        } else {
                            WhiteDivider()
                        }
                        HStack (alignment: .firstTextBaseline) {
                            if userViewData.accountType == "Athlete" {
                                let a = getAthlete(userViewData.email ?? "")
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
                            if userViewData.diveMeetsID != "" {
                                HStack {
                                    Image(systemName: "figure.pool.swim")
                                    if let diveMeetsID = userViewData.diveMeetsID {
                                        Text(diveMeetsID)
                                    } else {
                                        Text("?")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(width: screenWidth * 0.8)
            }
        }
    }
}

struct SettingsPage: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userViewData: UserViewData
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    var body: some View {
        ScrollView {
            VStack {
                BackgroundBubble(vPadding: 20, hPadding: 20) {
                    Text("Settings").font(.title2).fontWeight(.semibold)
                }
                ProfileImage(diverID: (userViewData.diveMeetsID ?? ""))
                    .scaleEffect(0.75)
                    .frame(width: 160, height: 160)
                Text((userViewData.firstName ?? "") + " " + (userViewData.lastName ?? ""))
                    .font(.title3).fontWeight(.semibold)
                Text(userViewData.email ?? "")
                    .foregroundColor(.secondary)
                if let phoneNum = userViewData.phone {
                    Text(phoneNum)
                        .foregroundColor(.secondary)
                }
                NavigationLink {
                    EditProfile(userViewData: $userViewData)
                } label: {
                    BackgroundBubble(shadow: 5) {
                        HStack {
                            Text("Edit Profile")
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.primary)
                        }
                        .padding()
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

struct EditProfile: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userViewData: UserViewData
    
    var body: some View {
        VStack {
            Text("This is where you will edit your account")
            NavigationLink(destination: CommittedCollegeView(userViewData: $userViewData)) {
                BackgroundBubble() {
                    Text("Choose College")
                        .foregroundColor(.primary)
                        .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
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

struct CommittedCollegeView: View {
    @State var college: String = ""
    @Binding var userViewData: UserViewData
    
    var body: some View {
        VStack {
            VStack {
                Text("Have you committed to dive in college?")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                Text("Start typing below to display your college on your profile")
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            SuggestionsTextField(userViewData: $userViewData)
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct SuggestionsTextField: View {
    @Environment(\.updateAthleteField) var updateAthleteField
    @Environment(\.getAthlete) var getAthlete
    @State var college: String = ""
    @State var suggestions: [String] = []
    @State var showSuggestions: Bool = false
    @State var selectedCollege: String = ""
    @Binding var userViewData: UserViewData
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            TextField("Start typing your college...", text: $college)
                .onChange(of: college) { newValue in
                    if newValue != selectedCollege {
                        showSuggestions = true
                        selectedCollege = ""
                    }
                }
                .textFieldStyle(.roundedBorder)
                .frame(width: screenWidth * 0.9)
            
            if selectedCollege != "" {
                Spacer()
                
                VStack {
                    Text("Current College")
                        .font(.title)
                        .bold()
                        .padding(.bottom)
                    BackgroundBubble() {
                        HStack {
                            Image(systemName: "gearshape")
                            Spacer()
                            Text(selectedCollege)
                            Spacer()
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .frame(width: 300)
                        .padding()
                    }
                }
                
                Spacer()
                Spacer()
            }
            
            if showSuggestions && !college.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .center) {
                        ForEach(suggestions.filter({ $0.localizedCaseInsensitiveContains(college) }),
                                id: \.self) { suggestion in
                            ZStack {
                                Button(action: {
                                    selectedCollege = suggestion
                                    college = selectedCollege
                                    showSuggestions = false
                                }) {
                                    BackgroundBubble() {
                                        HStack {
                                            Image(systemName: "gearshape")
                                            Spacer()
                                            Text(suggestion)
                                            Spacer()
                                            Spacer()
                                        }
                                        .foregroundColor(.primary)
                                        .frame(width: 200)
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            guard let colleges = getCollegeLogoData() else { return }
            suggestions = Array(colleges.keys)
            guard let email = userViewData.email else { return }
            print(getAthlete(email))
        }
        .onDisappear {
            if selectedCollege != "" {
                guard let email = userViewData.email else { return }
                updateAthleteField(email, "committedCollege", selectedCollege)
                print(getAthlete(email))
            }
        }
    }
}

struct DiveMeetsLink: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var userViewData: UserViewData
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
                            userViewData.diveMeetsID = diveMeetsID
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

struct WhiteDivider: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.white)
            .padding([.leading, .trailing], 3)
    }
}
