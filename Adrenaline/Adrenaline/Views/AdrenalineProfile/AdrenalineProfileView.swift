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
    @Binding var updateDataStoreData: Bool
    @Binding var user: NewUser?
    
    var authUserId: String
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    init(state: SignedInState, authUserId: String, showAccount: Binding<Bool>, 
         recentSearches: Binding<[SearchItem]>, updateDataStoreData: Binding<Bool>) {
        self.state = state
        self.authUserId = authUserId
        self._user = .constant(nil)
        self._showAccount = showAccount
        self._recentSearches = recentSearches
        self._updateDataStoreData = updateDataStoreData
    }
    
    init(state: SignedInState, newUser: Binding<NewUser?>, showAccount: Binding<Bool>,
         recentSearches: Binding<[SearchItem]>, updateDataStoreData: Binding<Bool>) {
        self.state = state
        self.authUserId = newUser.wrappedValue?.id ?? ""
        self._user = newUser
        self._showAccount = showAccount
        self._recentSearches = recentSearches
        self._updateDataStoreData = updateDataStoreData
    }
    
    var body: some View {
        ZStack {
            if let _ = user {
                AdrenalineProfileView(newUser: $user)
            } else {
                AdrenalineProfileView(authUserId: authUserId)
            }
        }
        .overlay {
            ProfileBar(state: state, showAccount: $showAccount, recentSearches: $recentSearches,
                       updateDataStoreData: $updateDataStoreData, user: user)
            .frame(width: screenWidth)
        }
    }
}

struct AdrenalineProfileView: View {
    @Environment(\.colorScheme) private var currentMode
    @Environment(\.dismiss) private var dismiss
    @State private var offset: CGFloat = 0
    @State private var swiped: Bool = false
    @Binding private var user: NewUser?
    
    var authUserId: String
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    init(authUserId: String) {
        self.authUserId = authUserId
        self._user = .constant(nil)
    }
    
    init(newUser: NewUser) {
        self.authUserId = newUser.id
        self._user = .constant(newUser)
    }
    
    init(newUser: Binding<NewUser?>) {
        self.authUserId = newUser.wrappedValue?.id ?? ""
        self._user = newUser
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
                    ProfileImage(profilePicURL: getProfilePictureURL(userId: user.id))
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
                        }
                    }
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
                    user = try await queryAWSUserById(id: authUserId)
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
                        Image(getCollegeImageFilename(name: selectedCollege))
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
                        
                        if user.accountType == "Athlete" {
                            if currentMode == .light {
                                Divider()
                            } else {
                                WhiteDivider()
                            }
                            
                            HStack (alignment: .firstTextBaseline) {
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
                    athlete = try await user.athlete
                    selectedCollege = try await athlete?.college?.name ?? ""
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

struct DiveMeetsLink: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var diveMeetsID: String = ""
    var newUser: NewUser
    
    @Binding var showAccount: Bool
    @Binding var updateDataStoreData: Bool
    
    // Computes Athlete skill ratings for newUser linking a DiveMeets account after intial creation
    private func assignSkillRatings(newUser: NewUser) async throws -> NewAthlete? {
        guard let diveMeetsID = newUser.diveMeetsID else { print("diveMeetsId nil"); return nil }
        guard var athlete = try await newUser.athlete else { print("athlete nil"); return nil }
        
        let (s, p, t) = await SkillRating().getSkillRating(diveMeetsID: diveMeetsID)

        athlete.springboardRating = s
        athlete.platformRating = p
        athlete.totalRating = t
        
        let result = try await saveToDataStore(object: athlete)
        
        updateDataStoreData = true
        return result
    }
    
    var body: some View {
        VStack {
            Text("Remake this view")
            
            TextField("DiveMeets ID", text: $diveMeetsID)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    var newUser = newUser
                    newUser.diveMeetsID = diveMeetsID
                    
                    do {
                        // Assign skill ratings for newUser
                        let _ = try await assignSkillRatings(newUser: newUser)
                    } catch {
                        print("\(error)")
                    }
                    
                    let _ = try await saveToDataStore(object: newUser)
                    
                    updateDataStoreData = true
                    
                    // Dismiss profile entirely so it can be redrawn with updated data
                    showAccount = false
                }
            } label: {
                Text("Link")
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
