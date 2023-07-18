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
    
    var body: some View {
        NavigationView{
            ZStack{
                GeometryReader{ geometry in
                    BackgroundSpheres()
                        .ignoresSafeArea()
                        .frame(height: geometry.size.height * 0.7)
                }
                
                VStack {
                    if firstSignIn {
                        BackgroundBubble(content: Text("Welcome " + (signupData.firstName ?? ""))
                            .font(.title2).fontWeight(.semibold)
                            .foregroundColor(.primary))
                    }
                    ProfileImage(diverID: "51197")
                    BackgroundBubble(content:
                                        Text((signupData.firstName ?? "") + " " + (signupData.lastName ?? "")) .font(.title).fontWeight(.semibold)
                                     , padding: 20)
                    .offset(y: -30)
                }
                .overlay{
                    BackgroundBubble(content:
                                        NavigationLink {
                        SettingsPage()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    })
                    .position(x: screenWidth * 0.55, y: screenHeight * 0.07)
                    .scaleEffect(1.4)
                }
                .offset(y: firstSignIn ? -screenHeight * 0.14 : -screenHeight * 0.25)
            }
        }
    }
}

struct SettingsPage: View {
    var body: some View {
        Text("Welcome to the settings page")
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
