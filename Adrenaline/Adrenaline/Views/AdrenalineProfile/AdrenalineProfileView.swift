//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct AdrenalineProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.getUser) private var getUser
    var firstSignIn: Bool = false
    @State private var offSet: CGFloat = 0
    //@Binding var diveMeetsID: String
    @Binding var user: User
    //@Binding var signupData: SignupData
    var athleteData: Athlete?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
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
        ZStack{
            // Universal Base View
            BackgroundSpheres()
                .ignoresSafeArea()
                .onAppear {
                    offSet = screenHeight * 0.48
                }
            
            VStack {
                HStack{
                    Spacer()
                    ProfileImage(diverID: user.diveMeetsID ?? "")
                        .scaleEffect(0.9)
                    Spacer()
                    VStack {
                        BackgroundBubble(vPadding: 20, hPadding: 20) {
                            VStack {
                                Text((user.firstName ?? "") + " " + (user.lastName
                                                    ?? "")) .font(.title3).fontWeight(.semibold)
//                                Text(signupData.accountType?.rawValue ?? "")
//                                    .foregroundColor(.secondary)
                            }
                        }
//                        BackgroundBubble() {
//                            HStack {
//                                HStack{
//                                    Image(systemName: "mappin.and.ellipse")
//                                    if signupData.recruiting == nil {
//                                        Text("?")
//                                    } else {
//                                        Text(formatLocationString(signupData.recruiting!.hometown ?? " "))
//                                    }
//                                }
//                                HStack {
//                                    Image(systemName: "person.fill")
//                                    if signupData.recruiting == nil {
//                                        Text("?")
//                                    } else {
//                                        Text(String(signupData.recruiting!.age ?? 0))
//                                    }
//
//                                }
//                            }
//                        }
                    }
                    Spacer()
                }
                .padding([.leading, .trailing])
            }
            .frame(width: screenWidth * 0.9)
//            .overlay{
//                BackgroundBubble() {
//                    NavigationLink {
//                        SettingsPage(user: $user)
//                    } label: {
//                        Image(systemName: "gear")
//                            .foregroundColor(.primary)
//                    }
//                }
//                .offset(x: screenWidth * 0.26, y: -screenHeight * 0.11)
//                .scaleEffect(1.4)
//            }
            .offset(y: firstSignIn ? -screenHeight * 0.14 : -screenHeight * 0.25)
            ZStack{
                Rectangle()
                    .foregroundColor(Custom.darkGray)
                    .cornerRadius(50)
                    .shadow(radius: 10)
                    .frame(width: screenWidth, height: screenHeight * 1.05)
                VStack {
                    DiverView(user: $user)
//                    if let type = signupData.accountType?.rawValue {
//                        if type == AccountType.athlete.rawValue {
//                            DiverView(user: $user)
//                        } else if type == AccountType.coach.rawValue {
//                            Text("This is a coaching profile")
//                            CoachView(diveMeetsID: $diveMeetsID)
//                        } else if type == AccountType.spectator.rawValue {
//                            Text("This is a spectator profile")
//                        } else {
//                            Text("The account type has not been specified")
//                        }
//                    } else {
//                        Text("Account type not selected")
//                    }
                }
            }
            .offset(y: offSet)
            .onSwipeGesture(trigger: .onEnded) { direction in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if direction == .up {
                        offSet = screenHeight * 0.13
                    } else if direction == .down {
                        offSet = screenHeight * 0.48
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
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

struct DiverView: View {
    @Binding var user: User
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    var body: some View {
        VStack {
            Spacer()
            // Showing DiveMeets Linking Screen
            if user.diveMeetsID == "" {
                BackgroundBubble(vPadding: 20, hPadding: 20) {
                    NavigationLink(destination: {
                        DiveMeetsLink(user: $user)
                    }, label: {
                        Text("Link DiveMeets Account")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                    })
                }
            } else {
                ProfileContent(user: $user)
                    .padding(.top, screenHeight * 0.05)
            }
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

struct CoachView: View {
    @Binding var user: User
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    var body: some View {
        BackgroundBubble() {
            NavigationLink(destination: {
                DiveMeetsLink(user: $user)
            }, label: { Text("Link to your DiveMeets Account") })
        }
    }
}

struct ProfileContent: View {
    @State var scoreValues: [String] = ["Meets", "Metrics", "Recruiting", "Statistics", "Videos"]
    @State var selectedPage: Int = 1
    @Binding var user: User
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 100
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        SwiftUIWheelPicker($selectedPage, items: scoreValues) { value in
            GeometryReader { g in
                Text(value)
                    .font(.title2).fontWeight(.semibold)
                    .frame(width: g.size.width, height: g.size.height,
                           alignment: .center)
            }
        }
        .scrollAlpha(0.3)
        .width(.Fixed(115))
        .scrollScale(0.7)
        .frame(height: 40)
        
        switch selectedPage {
        case 0:
            MeetList(profileLink:
                    "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                     (user.diveMeetsID ?? "00000"), nameShowing: false)
                .offset(y: -screenHeight * 0.05)
        case 1:
            MetricsView(user: $user)
        case 2:
            RecruitingView()
        case 3:
            StatisticsView()
        case 4:
            VideosView()
        default:
            MeetList(profileLink:
                     "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                     (user.diveMeetsID ?? "00000"), nameShowing: false)
        }
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

struct MetricsView: View {
    @Binding var user: User
    var body: some View {
        let profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + (user.diveMeetsID ?? "00000")
        SkillsGraph(profileLink: profileLink)
//            .frame(height: 300)
    }
}

struct RecruitingView: View {
    var body: some View {
        Text("Welcome to the Recruiting View")
    }
}

struct VideosView: View {
    var body: some View {
        Text("Welcome to the Videos View")
    }
}

struct StatisticsView: View {
    var body: some View {
        Text("Welcome to the Statistics View")
    }
}

//struct AdrenalineProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        let s  = SignupData(accountType: AccountType(rawValue: "athlete"), firstName: "Spencer", lastName: "Dearman", email: "dearmanspencer@gmail.com", phone: "571-758-8292", recruiting: RecruitingData(height: Height(feet: 6, inches: 0), weight: 168, gender: "Male", age: 19, gradYear: 2022, highSchool: "Oakton High School", hometown: "Oakton"))
//        AdrenalineProfileView(signupData: .constant(s), selectedOption: .constant(nil))
//    }
//}
