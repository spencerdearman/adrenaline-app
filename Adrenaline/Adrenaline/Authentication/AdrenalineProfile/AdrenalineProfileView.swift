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
enum AccountType: String, CaseIterable {
    case athlete = "Athlete"
    case coach = "Coach"
    case spectator = "Spectator"
}

enum WeightUnit: String, CaseIterable {
    case lb = "lb"
    case kg = "kg"
}

enum Gender: String, CaseIterable {
    case male = "M"
    case female = "F"
}

enum BasicInfoField: Int, Hashable, CaseIterable {
    case first
    case last
    case email
    case phone
    case password
    case repeatPassword
}

struct UserViewData: Equatable {
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var diveMeetsID: String?
    var accountType: String?
}

struct AdrenalineProfileView: View {
    @ObservedObject var state: SignedInState
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @State private var offset: CGFloat = 0
    @Binding var email: String
    @Binding var graphUser: GraphUser?
    @Binding var newAthlete: NewAthlete?
    @Binding var showAccount: Bool
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
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "ProfileBackground-Light" : "ProfileBackground-Dark")
                .frame(height: screenHeight * 0.7)
                .offset(x: screenWidth * 0.2, y: -screenHeight * 0.4)
                .scaleEffect(0.7)
            if let user = graphUser {
                VStack {
                    ProfileImage(diverID: (user.diveMeetsID ?? ""))
                        .frame(width: 200, height: 130)
                        .scaleEffect(0.9)
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                        .onAppear {
                            offset = screenHeight * 0.45
                        }
                    PersonalInfoView(graphUser: $graphUser, email: $email, athlete: $newAthlete)
                }
                .offset(y: -screenHeight * 0.25)
                .padding([.leading, .trailing, .top])
                .frame(width: screenWidth * 0.9)
                
                ZStack{
                    Rectangle()
                        .foregroundColor(Custom.darkGray)
                        .cornerRadius(50)
                        .shadow(radius: 10)
                        .frame(width: screenWidth, height: screenHeight * 0.8)
                    VStack {
                        let type = user.accountType
                        if type == AccountType.athlete.rawValue {
                            DiverView(graphUser: user)
                        } else if type == AccountType.coach.rawValue {
                            CoachView(graphUser: user)
                        } else if type == AccountType.spectator.rawValue {
                            Text("This is a spectator profile")
                        } else {
                            Text("The account type has not been specified")
                        }                    }
                }
                .frame(width: screenWidth)
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
        .overlay{
            ProfileBar(state: state, showAccount: $showAccount)
                .frame(width: screenWidth)
        }
//        .onAppear {
//            Task {
//                let emailPredicate = NewUser.keys.email == email
//                let users = await queryUsers(where: emailPredicate)
//                if users.count >= 1 {
//                    graphUser = users[0]
//                    print(graphUser)
//                    let userPredicate = users[0].athleteId ?? "" == NewAthlete.keys.id.rawValue
//                    let athletes = await queryAWSAthletes(where: userPredicate as? QueryPredicate)
//                    print(athletes)
//                    if athletes.count >= 1 {
//                        newAthlete = athletes[0]
//                        print(newAthlete)
//                    }
//                }
//            }
//        }
    }
}

struct PersonalInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var graphUser: GraphUser?
    @Binding var email: String
    @Binding var athlete: NewAthlete?
    @State var selectedCollege: String = ""
    @State private var starred: Bool = false
    @State var isShowingStar: Bool = true
    @ScaledMetric private var collegeIconPaddingScaled: CGFloat = -8.0
    @ScaledMetric private var bubbleHeightScaled: CGFloat = 85
    
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
                    if let user = graphUser {
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
                                            withAnimation {
                                                starred.toggle()
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
                        }
                    } else {
                        Text("Error with Graph User")
                    }
                }
                .frame(width: screenWidth * 0.8)
            }
        }
        .dynamicTypeSize(.xSmall ... .xxLarge)
        .onAppear {
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
    var graphUser: GraphUser
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
