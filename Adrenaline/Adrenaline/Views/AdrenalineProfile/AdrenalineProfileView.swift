//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

func getCollegeImageFilename(name: String) -> String {
    return name.replacingOccurrences(of: " ", with: "_")
}

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
                    PersonalInfoView(userViewData: $userViewData, loginSuccessful: $loginSuccessful)
                }
                .offset(y: -screenHeight * 0.3)
                .padding([.leading, .trailing, .top])
                .frame(width: screenWidth * 0.9)
                .overlay{
                    if loginSuccessful {
                        BackgroundBubble(vPadding: 20, hPadding: 35) {
                            Text("Logout")
                                .onTapGesture {
                                    withAnimation {
                                        clearCredentials(email: userEmail)
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
                                DiverView(userViewData: $userViewData,
                                          loginSuccessful: $loginSuccessful)
                            } else if type == AccountType.coach.rawValue {
                                CoachView(userViewData: $userViewData,
                                          loginSuccessful: $loginSuccessful)
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
            if userViewData == UserViewData() {
                guard let storedUser = getUser(userEmail) else { return }
                user = storedUser
                userViewData = userEntityToViewData(user: storedUser)
            }
        }
    }
}

struct PersonalInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.getUser) private var getUser
    @Environment(\.getAthlete) private var getAthlete
    @Environment(\.addFollowedByEmail) private var addFollowedByEmail
    @Environment(\.getFollowedByEmail) private var getFollowedByEmail
    @Environment(\.dropFollowedFromUser) private var dropFollowedFromUser
    @Environment(\.addFollowedToUser) private var addFollowedToUser
    @State var selectedCollege: String = ""
    @State private var starred: Bool = false
    @Binding var userViewData: UserViewData
    @Binding var loginSuccessful: Bool
    @ScaledMetric private var collegeIconPaddingScaled: CGFloat = -8.0
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var collegeIconPadding: CGFloat {
        collegeIconPaddingScaled * 2.2
    }
    
    private var isShowingStar: Bool {
        guard let (loggedInEmail, _) = getStoredCredentials() else { return false }
        return userViewData.accountType != "Spectator" && !loginSuccessful &&
        userViewData.email != loggedInEmail
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
    
    private func updateFollowed() {
        guard let first = userViewData.firstName, let last = userViewData.lastName,
                let userEmail = userViewData.email else { return }
        print("before")
        addFollowedByEmail(first, last, userEmail)
        print("after")
        guard let (email, _) = getStoredCredentials() else { return }
        guard let user = getUser(email) else { return }
        guard let followed = getFollowedByEmail(userEmail) else { return }
        
        addFollowedToUser(user, followed)
    }
    
    private func isFollowedByUser(email: String, user: User) -> Bool {
        for followed in user.followedArray {
            if followed.email == email {
                return true
            }
        }
        
        return false
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
                            if isShowingStar {
                                Image(systemName: starred ? "star.fill" : "star")
                                    .foregroundColor(starred
                                                     ? Color.yellow
                                                     : Color.primary)
                                    .onTapGesture {
                                        withAnimation {
                                            starred.toggle()
                                            if starred {
                                                updateFollowed()
                                            } else {
                                                guard let email = userViewData.email else { return }
                                                // Gets logged in user
                                                guard let (loggedInEmail, _) =
                                                        getStoredCredentials() else {
                                                    return
                                                }
                                                guard let user = getUser(loggedInEmail) else {
                                                    return
                                                }
                                                guard let followed = getFollowedByEmail(email)
                                                else { return }
                                                dropFollowedFromUser(user, followed)
                                            }
                                        }
                                    }
                            }
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
                    .overlay(selectedCollege == ""
                             ? AnyView(EmptyView())
                             : AnyView(
                                Image(selectedCollege)
                            .resizable()
                            .clipShape(Circle())
                            .aspectRatio(contentMode: .fit)
                            .padding(.leading, collegeIconPadding)),
                             alignment: .leading)
            }
        }
        .dynamicTypeSize(.xSmall ... .xxLarge)
        .onAppear {
            if userViewData.accountType == "Athlete",
               let a = getAthlete(userViewData.email ?? "") {
                if let college = a.committedCollege {
                    selectedCollege = getCollegeImageFilename(name: college)
                } else {
                    selectedCollege = ""
                }
            }
            
            if isShowingStar {
                // Gets logged in user
                guard let (loggedInEmail, _) = getStoredCredentials() else { return }
                guard let user = getUser(loggedInEmail) else { return }
                
                guard let email = userViewData.email else { return }
                if isFollowedByUser(email: email, user: user) {
                    starred = true
                } else {
                    starred = false
                }
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
    @Environment(\.dismiss) private var dismiss
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
                Text("Start typing below to choose a college to display on your profile")
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            SuggestionsTextField(userViewData: $userViewData)
            Spacer()
            Spacer()
        }
        .padding()
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

// https://stackoverflow.com/questions/76389104/how-to-create-autocomplete-textfield-in-swiftui
struct SuggestionsTextField: View {
    @Environment(\.updateAthleteField) var updateAthleteField
    @Environment(\.getAthlete) var getAthlete
    @State var college: String = ""
    @State var suggestions: [String] = []
    @State var suggestionsImages: [URL: UIImage] = [:]
    @State var showSuggestions: Bool = false
    @State var selectedCollege: String = ""
    @Binding var userViewData: UserViewData
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    @ScaledMetric private var imgScaleScaled: CGFloat = 0.7
    
    private let colleges: [String: String]? = getCollegeLogoData()
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var imgScale: CGFloat {
        min(imgScaleScaled, 1.1)
    }
    
    private var selectedCollegeImage: Image? {
        selectedCollege != "" ? Image(getCollegeImageFilename(name: selectedCollege)) : nil
    }
    
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
                            if let image = selectedCollegeImage {
                                image
                                    .resizable()
                                    .clipShape(Circle())
                                    .scaleEffect(imgScale)
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                ProgressView()
                            }
                            Spacer()
                            
                            Text(selectedCollege)
                            
                            Spacer()
                            Spacer()
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .frame(width: screenWidth * 0.8, height: screenWidth * 0.3)
                        .padding()
                    }
                    
                    if selectedCollege != "" {
                        ZStack {
                            Rectangle()
                                .foregroundColor(Custom.darkGray)
                                .cornerRadius(50)
                                .shadow(radius: 10)
                            Text("Clear")
                        }
                        .frame(width: screenWidth * 0.15, height: screenHeight * 0.05)
                        .onTapGesture {
                            selectedCollege = ""
                        }
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
                                            Image(getCollegeImageFilename(name: suggestion))
                                                .resizable()
                                                .clipShape(Circle())
                                                .scaleEffect(min(imgScale, 1.0))
                                                .aspectRatio(contentMode: .fit)
                                            
                                            Spacer()
                                            
                                            Text(suggestion)
                                            
                                            Spacer()
                                            Spacer()
                                        }
                                        .foregroundColor(.primary)
                                        .frame(width: screenWidth * 0.80, height: screenWidth * 0.2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, maxHeightOffset)
                }
            }
        }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        .onAppear {
            // Gets colleges for suggestions
            guard let colleges = colleges else { return }
            suggestions = Array(colleges.keys)
            
            // Checks if athlete already has a selected college and updates view if so
            guard let email = userViewData.email else { return }
            if let athlete = getAthlete(email),
               let college = athlete.committedCollege {
                selectedCollege = college
            }
        }
        .onDisappear {
            guard let email = userViewData.email else { return }
            
            // Saves selected college to athlete entity if it is not empty
            if selectedCollege != "" {
                updateAthleteField(email, "committedCollege", selectedCollege)
            } else {
                updateAthleteField(email, "committedCollege", nil)
            }
        }
    }
}

struct DiveMeetsLink: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.updateUserField) private var updateUserField
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
                    .frame(width: textFieldWidth) }
            }
            BackgroundBubble(onTapGesture: {
                if let email = userViewData.email {
                    updateUserField(email, "diveMeetsID", diveMeetsID)
                    userViewData.diveMeetsID = diveMeetsID
                }
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
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
