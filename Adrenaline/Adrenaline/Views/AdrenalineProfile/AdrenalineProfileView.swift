//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct DiverCoachAccounts: Hashable {
    var diveMeetsID: String?
    var usaDivingID: String?
    var aauDivingID: String?
    var ncaaID: String?
}

struct AdrenalineProfileView: View {
    @Environment(\.dismiss) private var dismiss
    var firstSignIn: Bool = false
    @State private var personalAccount: DiverCoachAccounts? = nil
    @State private var offSet: CGFloat = 0
    @Binding var diveMeetsID: String
    @Binding var signupData: SignupData
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    func formatLocationString(_ input: String) -> String {
        var formattedString = input
        
        if let spaceIndex = input.firstIndex(of: " ") {
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
                    ProfileImage(diverID: diveMeetsID)
                        .scaleEffect(0.9)
                    Spacer()
                    VStack {
                        BackgroundBubble(vPadding: 20, hPadding: 20) {
                            VStack {
                                Text((signupData.firstName ?? "") + " " + (signupData.lastName
                                                    ?? "")) .font(.title3).fontWeight(.semibold)
                                Text(signupData.accountType?.rawValue ?? "")
                                    .foregroundColor(.secondary)
                            }
                        }
                        BackgroundBubble() {
                            HStack {
                                HStack{
                                    Image(systemName: "mappin.and.ellipse")
                                    if signupData.recruiting == nil {
                                        Text("?")
                                    } else {
                                        Text(formatLocationString(signupData.recruiting!.hometown ?? " "))
                                    }
                                }
                                HStack {
                                    Image(systemName: "person.fill")
                                    if signupData.recruiting == nil {
                                        Text("?")
                                    } else {
                                        Text(String(signupData.recruiting!.age ?? 0))
                                    }

                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            .overlay{
                BackgroundBubble() {
                    NavigationLink {
                        SettingsPage(signupData: $signupData, diveMeetsID: $diveMeetsID)
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                }
                .offset(x: screenWidth * 0.26, y: -screenHeight * 0.11)
                .scaleEffect(1.4)
            }
            .offset(y: firstSignIn ? -screenHeight * 0.14 : -screenHeight * 0.25)
            ZStack{
                Rectangle()
                    .foregroundColor(Custom.darkGray)
                    .cornerRadius(50)
                    .shadow(radius: 10)
                    .frame(height: screenHeight * 1.1)
                VStack {
                    if let type = signupData.accountType?.rawValue {
                        if type == AccountType.athlete.rawValue {
                            DiverView(diveMeetsID: $diveMeetsID, personalAccount: $personalAccount)
                        } else if type == AccountType.coach.rawValue {
                            Text("This is a coaching profile")
                            CoachView(diveMeetsID: $diveMeetsID, personalAccount: $personalAccount)
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
    @Binding var signupData: SignupData
    @Binding var diveMeetsID: String
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    var body: some View {
        ScrollView {
            VStack {
                Group {
                    BackgroundBubble(vPadding: 20, hPadding: 20) {
                        Text("Settings").font(.title2).fontWeight(.semibold)
                    }
                    ProfileImage(diverID: diveMeetsID)
                        .scaleEffect(0.75)
                        .frame(width: 150, height: 160)
                    Text((signupData.firstName ?? "") + " " + (signupData.lastName ?? ""))
                        .font(.title3).fontWeight(.semibold)
                    Text(signupData.email ?? "")
                        .foregroundColor(.secondary)
                    if let phoneNum = signupData.phone {
                        Text(phoneNum)
                            .foregroundColor(.secondary)
                    }
                }
                Group {
                    NavigationLink {
                        EditProfile()
                    } label: {
                        HStack {
                            BackgroundBubble(color: Custom.coolBlue, vPadding: 20, hPadding: 20) {
                                HStack {
                                    Text("Edit Profile")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                Group {
                    Text("Profile Information")
                    Divider()
                    Text("Update Email")
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: textFieldWidth)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .onChange(of: email) { _ in
                            signupData.email = email
                        }
                    Text("Update Password")
                    //NEED PASSWORD FIELD
                    Text("Update Phone Number")
                    TextField("Phone", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.numberPad)
                        .frame(width: textFieldWidth)
                        .onChange(of: phoneNumber) { _ in
                            signupData.phone = phoneNumber
                        }
                    Divider()
                    Text("Preferences")
                    Divider()
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
    var body: some View {
        Text("This is where you will edit your account")
    }
}

struct DiverView: View {
    @Binding var diveMeetsID: String
    @Binding var personalAccount: DiverCoachAccounts?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    var body: some View {
        VStack {
            Spacer()
            // Showing DiveMeets Linking Screen
            if diveMeetsID == "" {
                BackgroundBubble(vPadding: 20, hPadding: 20) {
                    NavigationLink(destination: {
                        DiveMeetsLink(diveMeetsID: $diveMeetsID, personalAccount: $personalAccount)
                    }, label: {
                        Text("Link DiveMeets Account")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                    })
                }
            } else {
                ProfileContent(diveMeetsID: $diveMeetsID)
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
    @Binding var diveMeetsID: String
    @Binding var personalAccount: DiverCoachAccounts?
    private let linkHead: String =
    "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
    var body: some View {
        BackgroundBubble() {
            NavigationLink(destination: {
                DiveMeetsLink(diveMeetsID: $diveMeetsID, personalAccount: $personalAccount)
            }, label: { Text("Link to your DiveMeets Account") })
        }
    }
}

struct ProfileContent: View {
    @State var scoreValues: [String] = ["Meets", "Metrics", "Recruiting", "Statistics", "Videos"]
    @State var selectedPage: Int = 1
    @Binding var diveMeetsID: String
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
                     diveMeetsID, nameShowing: false)
                .offset(y: -screenHeight * 0.05)
        case 1:
            MetricsView()
        case 2:
            RecruitingView()
        case 3:
            StatisticsView()
        case 4:
            VideosView()
        default:
            MeetList(profileLink:
                     "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" +
                     diveMeetsID, nameShowing: false)
        }
    }
}

struct DiveMeetsLink: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var diveMeetsID: String
    @Binding var personalAccount: DiverCoachAccounts?
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
                            personalAccount?.diveMeetsID = diveMeetsID
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
    var body: some View {
        Text("Welcome to the Metrics View")
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
