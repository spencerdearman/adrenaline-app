//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct AdrenalineProfileView: View {
    var firstSignIn: Bool = false
    @Binding var signupData: SignupData
    @Binding var selectedOption: AccountType?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @State var offSet: CGFloat = 0
    
    var body: some View {
            ZStack{
                // Universal Base View
                BackgroundSpheres()
                    .ignoresSafeArea()
                    .onAppear {
                        offSet = screenHeight * 0.48
                    }
                
                VStack {
                    if firstSignIn {
                        BackgroundBubble(content: Text("Welcome " + (signupData.firstName ?? ""))
                            .font(.title2).fontWeight(.semibold)
                            .foregroundColor(.primary))
                    }
                    ProfileImage(diverID: "51197")
                        .position(x: screenWidth / 2, y: screenHeight * 0.5)
                    BackgroundBubble(content:
                                        Text((signupData.firstName ?? "") + " " + (signupData.lastName ?? "")) .font(.title).fontWeight(.semibold)
                                     , padding: 20)
                    .offset(y: -screenHeight * 0.4)
                }
                .overlay{
                    BackgroundBubble(content:
                                        NavigationLink {
                        SettingsPage()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    })
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
                    
                    if let type = signupData.accountType {
                        if type.rawValue == AccountType.athlete.rawValue {
                            Text("This is an athlete profile")
                                .foregroundColor(.primary)
                        } else if type.rawValue == AccountType.coach.rawValue {
                            Text("This is a coaching profile")
                        } else if type.rawValue == AccountType.spectator.rawValue {
                            Text("This is a spectator profile")
                        } else {
                            Text("The account type has not been specified")
                        }
                    } else {
                        Text("Account type not selected")
                    }
//                    BackgroundBubble(content:
//                                        NavigationLink(destination: {
//                        DiveMeetsLink()
//                    }, label: { Text("Link to your DiveMeets Account") }))
                }
                .offset(y: offSet)
                .animation(.easeInOut(duration: 0.25))
                .onSwipeGesture(trigger: .onEnded) { direction in
                    if direction == .up {
                        offSet = screenHeight * 0.13
                    } else if direction == .down {
                        offSet = screenHeight * 0.48
                    }
                }
                
                // For Athletes Specifically
                
                
                
            }
    }
}

struct SettingsPage: View {
    var body: some View {
        Text("Welcome to the settings page")
    }
}

struct DiveMeetsLink: View{
    var body: some View {
        Text("Link to your divemeets account here")
    }
}

//struct SignupData: Hashable {
//    var accountType: AccountType?
//    var firstName: String?
//    var lastName: String?
//    var email: String?
//    var phone: String?
//    var recruiting: RecruitingData?
//}
//struct RecruitingData: Hashable {
//    var height: Height?
//    var weight: Int?
//    var gender: String?
//    var age: Int?
//    var gradYear: Int?
//    var highSchool: String?
//    var hometown: String?
//}
//
//struct Height: Hashable {
//    var feet: Int
//    var inches: Int
//}
//

struct AdrenalineProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let s  = SignupData(accountType: AccountType(rawValue: "athlete"), firstName: "Spencer",
                            lastName: "Dearman", email: "dearmanspencer@gmail.com",
                            phone: "571-758-8292",
                            recruiting: RecruitingData(height: Height(feet: 6, inches: 0),
                                                       weight: Weight(weight: 168, unit: .lb),
                                                       gender: "Male", age: 19,
                                                       gradYear: 2022,
                                                       highSchool: "Oakton High School",
                                                       hometown: "Oakton"))
        AdrenalineProfileView(signupData: .constant(s), selectedOption: .constant(nil))
    }
}
