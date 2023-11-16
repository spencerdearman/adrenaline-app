//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI
import Amplify
import Authenticator

func getCollegeImageFilename(name: String) -> String {
    return name.replacingOccurrences(of: " ", with: "_")
}

// Wrapper view to decouple the ProfileBar that requires state and showAccount from a general
// profile view
struct AdrenalineProfileWrapperView: View {
    @ObservedObject private var state: SignedInState
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    
    var user: NewUser?
    var authUserId: String
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    init(state: SignedInState, authUserId: String, showAccount: Binding<Bool>, recentSearches: Binding<[SearchItem]>) {
        self.state = state
        self.authUserId = authUserId
        self.user = nil
        self._showAccount = showAccount
        self._recentSearches = recentSearches
    }
    
    init(state: SignedInState, newUser: NewUser, showAccount: Binding<Bool>, recentSearches: Binding<[SearchItem]>) {
        self.state = state
        self.authUserId = newUser.id
        self.user = newUser
        self._showAccount = showAccount
        self._recentSearches = recentSearches
    }
    
    var body: some View {
        ZStack {
            if let user = user {
                AdrenalineProfileView(newUser: user)
            } else {
                AdrenalineProfileView(authUserId: authUserId)
            }
        }
        .overlay{
            ProfileBar(state: state, showAccount: $showAccount, recentSearches: $recentSearches, user: user)
                .frame(width: screenWidth)
        }
    }
}

struct AdrenalineProfileView: View {
    @Environment(\.colorScheme) private var currentMode
    @Environment(\.dismiss) private var dismiss
    @State private var offset: CGFloat = 0
    @State private var swiped: Bool = false
    @State private var user: NewUser? = nil
    
    var authUserId: String
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    init(authUserId: String) {
        self.authUserId = authUserId
    }
    
    init(newUser: NewUser) {
        self.authUserId = newUser.id
        user = newUser
    }
    
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
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "ProfileBackground-Light" : "ProfileBackground-Dark")
                .frame(height: screenHeight * 0.7)
                .offset(x: screenWidth * 0.2, y: -screenHeight * 0.4)
                .scaleEffect(0.7)
            
            if let user = user {
                VStack {
                    ProfileImage(diverID: (user.diveMeetsID ?? ""))
                        .frame(width: 200, height: 130)
                        .scaleEffect(0.9)
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                        .onAppear {
                            offset = screenHeight * 0.45
                        }
                    PersonalInfoView(user: user)
                }
                .offset(y: -screenHeight * 0.25)
                .padding([.leading, .trailing, .top])
                .frame(width: screenWidth * 0.9)
                
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .cornerRadius(50)
                        .shadow(radius: 10)
                    VStack {
                        let type = user.accountType
                        if type == AccountType.athlete.rawValue {
                            DiverView(newUser: user)
                        } else if type == AccountType.coach.rawValue {
                            CoachView(newUser: user)
                        } else if type == AccountType.spectator.rawValue {
                            Text("This is a spectator profile")
                        } else {
                            Text("The account type has not been specified")
                        }                    }
                }
                .frame(width: screenWidth, height: swiped ? screenHeight * 0.85: screenHeight * 0.6)
                .onSwipeGesture(trigger: .onChanged) { direction in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if direction == .up {
                            swiped = true
                        } else if direction == .down {
                            swiped = false
                        }
                    }
                }
                .offset(y: swiped ? screenHeight * 0.07 : screenHeight * 0.25)
            }
        }
        .onAppear {
            if user == nil {
                Task {
                    let pred = NewUser.keys.id == authUserId
                    let users = await queryAWSUsers(where: pred)
                    
                    if users.count == 1 {
                        user = users[0]
                    }
                }
            }
        }
    }
}

struct PersonalInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var athlete: NewAthlete? = nil
    @State var selectedCollege: String = ""
    @State private var starred: Bool = false
    @State private var currentUser: NewUser? = nil
    @AppStorage("authUserId") private var authUserId: String = ""
    @ScaledMetric private var collegeIconPaddingScaled: CGFloat = -8.0
    @ScaledMetric private var bubbleHeightScaled: CGFloat = 85
    
    var user: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var collegeIconPadding: CGFloat {
        collegeIconPaddingScaled * 2.2
    }
    
    private var bubbleHeight: CGFloat {
        switch dynamicTypeSize {
            case .xSmall, .small, .medium:
                return 85
            default:
                return bubbleHeightScaled * 1.2
        }
    }
    
    private var isShowingStar: Bool {
        user.id != authUserId
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
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: screenWidth * 0.9, height: bubbleHeight)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 10)
                HStack {
                    if selectedCollege != "" {
                        Image(selectedCollege)
                            .resizable()
                            .clipShape(Circle())
                            .aspectRatio(contentMode: .fit)
                            .padding(.leading, collegeIconPadding)
                            .frame(width: screenWidth * 0.15,
                                   height: screenWidth * 0.15)
                    }
                    
                    VStack {
                        HStack (alignment: .firstTextBaseline) {
                            Text((user.firstName) + " " +
                                 (user.lastName)).font(.title3).fontWeight(.semibold)
                            Text(user.accountType)
                                .foregroundColor(.secondary)
                            if isShowingStar {
                                Image(systemName: starred ? "star.fill" : "star")
                                    .foregroundColor(starred
                                                     ? Color.yellow
                                                     : Color.primary)
                                    .onTapGesture {
                                        Task {
                                            withAnimation {
                                                starred.toggle()
                                            }
                                            
                                            if let currentUser = currentUser {
                                                // If current user just favorited the profile,
                                                if starred {
                                                    print("Starred, following...")
                                                    await follow(follower: currentUser,
                                                                 followingId: user.id)
                                                } else {
                                                    print("Unstarred, unfollowing...")
                                                    await unfollow(follower: currentUser,
                                                                   unfollowingId: user.id)
                                                }
                                            }
                                        }
                                    }
                                
                            }
                        }
                        if user.accountType != "Spectator" {
                            if currentMode == .light {
                                Divider()
                            } else {
                                WhiteDivider()
                            }
                            HStack (alignment: .firstTextBaseline) {
                                //                                    if user.accountType == "Athlete" {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                    if let hometown = athlete?.hometown, !hometown.isEmpty {
                                        Text(hometown)
                                    } else {
                                        Text("?")
                                    }
                                }
                                HStack {
                                    Image(systemName: "person.fill")
                                    if let age = athlete?.age {
                                        Text(String(age))
                                    } else {
                                        Text("?")
                                    }
                                }
                                //                                    }
                            }
                        }
                    }
                }
                .frame(width: screenWidth * 0.8)
            }
        }
        .dynamicTypeSize(.xSmall ... .xxLarge)
        .onAppear {
            Task {
                if user.accountType == "Athlete" {
                    let athletes = await queryAWSAthletes().filter { $0.user.id == user.id }
                    if athletes.count == 1 {
                        athlete = athletes[0]
                    }
                }
                
                // Get current user for favoriting
                let pred = NewUser.keys.id == authUserId
                let users = await queryAWSUsers(where: pred)
                if users.count == 1 {
                    currentUser = users[0]
                }
                
                if let currentUser = currentUser, currentUser.favoritesIds.contains(user.id) {
                    withAnimation {
                        starred = true
                    }
                }
            }
        }
    }
}

//struct CommittedCollegeView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State var college: String = ""
//    //@Binding var userViewData: UserViewData
//
//    var body: some View {
//        VStack {
//            VStack {
//                Text("Have you committed to dive in college?")
//                    .font(.title)
//                    .bold()
//                    .multilineTextAlignment(.center)
//                    .padding(.bottom)
//                Text("Start typing below to choose a college to display on your profile")
//                    .font(.title2)
//                    .multilineTextAlignment(.center)
//            }
//            Spacer()
//            SuggestionsTextField(userViewData: $userViewData)
//            Spacer()
//            Spacer()
//        }
//        .padding()
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: { dismiss() }) {
//                    NavigationViewBackButton()
//                }
//            }
//        }
//    }
//}

// https://stackoverflow.com/questions/76389104/how-to-create-autocomplete-textfield-in-swiftui
//struct SuggestionsTextField: View {
//    @Environment(\.updateAthleteField) var updateAthleteField
//    @Environment(\.getAthlete) var getAthlete
//    @State var college: String = ""
//    @State var suggestions: [String] = []
//    @State var suggestionsImages: [URL: UIImage] = [:]
//    @State var showSuggestions: Bool = false
//    @State var selectedCollege: String = ""
//    @Binding var userViewData: UserViewData
//    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
//    @ScaledMetric private var imgScaleScaled: CGFloat = 0.7
//
//    private let colleges: [String: String]? = getCollegeLogoData()
//    private let screenWidth = UIScreen.main.bounds.width
//    private let screenHeight = UIScreen.main.bounds.height
//
//    private var maxHeightOffset: CGFloat {
//        min(maxHeightOffsetScaled, 90)
//    }
//
//    private var imgScale: CGFloat {
//        min(imgScaleScaled, 1.1)
//    }
//
//    private var selectedCollegeImage: Image? {
//        selectedCollege != "" ? Image(getCollegeImageFilename(name: selectedCollege)) : nil
//    }
//
//    var body: some View {
//        VStack {
//            TextField("Start typing your college...", text: $college)
//                .onChange(of: college) { newValue in
//                    if newValue != selectedCollege {
//                        showSuggestions = true
//                        selectedCollege = ""
//                    }
//                }
//                .textFieldStyle(.roundedBorder)
//                .frame(width: screenWidth * 0.9)
//
//            if selectedCollege != "" {
//                Spacer()
//
//                VStack {
//                    Text("Current College")
//                        .font(.title)
//                        .bold()
//                        .padding(.bottom)
//                    BackgroundBubble() {
//                        HStack {
//                            if let image = selectedCollegeImage {
//                                image
//                                    .resizable()
//                                    .clipShape(Circle())
//                                    .scaleEffect(imgScale)
//                                    .aspectRatio(contentMode: .fit)
//                            } else {
//                                ProgressView()
//                            }
//                            Spacer()
//
//                            Text(selectedCollege)
//
//                            Spacer()
//                            Spacer()
//                            Spacer()
//                        }
//                        .foregroundColor(.primary)
//                        .frame(width: screenWidth * 0.8, height: screenWidth * 0.3)
//                        .padding()
//                    }
//
//                    if selectedCollege != "" {
//                        ZStack {
//                            Rectangle()
//                                .foregroundColor(Custom.darkGray)
//                                .cornerRadius(50)
//                                .shadow(radius: 10)
//                            Text("Clear")
//                        }
//                        .frame(width: screenWidth * 0.15, height: screenHeight * 0.05)
//                        .onTapGesture {
//                            selectedCollege = ""
//                        }
//                    }
//                }
//
//                Spacer()
//                Spacer()
//            }
//
//            if showSuggestions && !college.isEmpty {
//                ScrollView {
//                    LazyVStack(alignment: .center) {
//                        ForEach(suggestions.filter({ $0.localizedCaseInsensitiveContains(college) }),
//                                id: \.self) { suggestion in
//                            ZStack {
//                                Button(action: {
//                                    selectedCollege = suggestion
//                                    college = selectedCollege
//                                    showSuggestions = false
//                                }) {
//                                    BackgroundBubble() {
//                                        HStack {
//                                            Image(getCollegeImageFilename(name: suggestion))
//                                                .resizable()
//                                                .clipShape(Circle())
//                                                .scaleEffect(min(imgScale, 1.0))
//                                                .aspectRatio(contentMode: .fit)
//
//                                            Spacer()
//
//                                            Text(suggestion)
//
//                                            Spacer()
//                                            Spacer()
//                                        }
//                                        .foregroundColor(.primary)
//                                        .frame(width: screenWidth * 0.80, height: screenWidth * 0.2)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .padding(.top)
//                    .padding(.bottom, maxHeightOffset)
//                }
//            }
//        }
//        .dynamicTypeSize(.xSmall ... .xxxLarge)
//        .onAppear {
//            // Gets colleges for suggestions
//            guard let colleges = colleges else { return }
//            suggestions = Array(colleges.keys)
//
//            // Checks if athlete already has a selected college and updates view if so
//            guard let email = userViewData.email else { return }
//            if let athlete = getAthlete(email),
//               let college = athlete.committedCollege {
//                selectedCollege = college
//            }
//        }
//        .onDisappear {
//            guard let email = userViewData.email else { return }
//
//            // Saves selected college to athlete entity if it is not empty
//            if selectedCollege != "" {
//                updateAthleteField(email, "committedCollege", selectedCollege)
//            } else {
//                updateAthleteField(email, "committedCollege", nil)
//            }
//        }
//    }
//}

struct DiveMeetsLink: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    var newUser: NewUser
    var body: some View {
        VStack {
            Text("ReMake the DiveMeets Link")
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
