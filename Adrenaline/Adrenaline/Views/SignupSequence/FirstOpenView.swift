//
//  FirstOpenView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

struct SignupData: Hashable {
    var accountType: AccountType?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var recruiting: RecruitingData?
}

struct RecruitingData: Hashable {
    var height: Height?
    var weight: Int?
    var gender: String?
    var age: Int?
    var gradYear: Int?
    var highSchool: String?
    var hometown: String?
}

struct Height: Hashable {
    var feet: Int
    var inches: Int
}

struct FirstOpenView: View {
    @State var signupData = SignupData()
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .frame(width: screenWidth * 0.9, height: 125)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 6)
                VStack {
                    Text("Welcome to Adrenaline")
                        .font(.title)
                    .bold()
                    HStack {
                        NavigationLink(destination: ProfileView(profileLink: "")) {
                            Text("Login")
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(40)
                        .foregroundColor(.primary)
                        NavigationLink(destination: AccountTypeSelectView(signupData: $signupData)) {
                            Text("Sign Up")
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(40)
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct FirstOpenView_Previews: PreviewProvider {
    static var previews: some View {
        FirstOpenView()
    }
}
