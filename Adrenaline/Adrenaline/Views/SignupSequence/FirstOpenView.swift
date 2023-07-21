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
    var password: String?
    var recruiting: RecruitingData?
    
    private let defaults = UserDefaults.standard
    
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(email)  {
            defaults.set(encoded, forKey: "username")
        }
        
        do {
            try saveToKeychain(value: password, for: email)
        } catch {
            print("Unable to save password to keychain")
        }
    }
    
    func clear() {
        defaults.removeObject(forKey: "username")
        do {
            try deleteFromKeychain(for: email)
        } catch {
            print("Unable to delete password from keychain")
        }
    }
}

struct LoginData: Hashable {
    var username: String?
    var password: String?
    
    mutating func loadStoredCredentials() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "username") {
            let username = try? decoder.decode(String.self, from: data)
            self.username = username
        }
        
        self.password = try? readFromKeychain(for: username)
    }
}

struct RecruitingData: Hashable {
    var height: Height?
    var weight: Weight?
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

struct Weight: Hashable {
    var weight: Int
    var unit: WeightUnit
}

struct FirstOpenView: View {
    @State var signupData = SignupData()
    @State var loginData = LoginData()
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundBubble() {
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
                    .padding()
                }
            }
        }
        .onAppear {
            loginData.loadStoredCredentials()
            
            if let username = loginData.username,
               let password = loginData.password {
                print("Username: \(username)")
                print("Password: \(password)")
            }
        }
    }
}

struct FirstOpenView_Previews: PreviewProvider {
    static var previews: some View {
        FirstOpenView()
    }
}
