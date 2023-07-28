//
//  LoginPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/27/23.
//

import SwiftUI

struct LoginPage: View {
    @Environment(\.getUser) private var getUser
    @Environment(\.validatePassword) private var validatePassword
    @State var isPasswordVisible: Bool = false
    @State var username: String = ""
    @State var password: String = ""
    @State var loginData: LoginData = LoginData()
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private func emailInDatabase(email: String) -> Bool {
        return getUser(email) != nil
    }
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textContentType(.newPassword)
                .multilineTextAlignment(.center)
                .padding()
                .onChange(of: username) { _ in
                    loginData.username = username
                }
            HStack {
                (isPasswordVisible
                 ? AnyView(TextField("Password", text: $password))
                 : AnyView(SecureField("Password", text: $password)))
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textContentType(.newPassword)
                .multilineTextAlignment(.center)
                .onChange(of: password) { _ in
                    loginData.password = password
                }
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible
                          ? "eye.circle"
                          : "eye.slash.circle")
                    .foregroundColor(.gray)
                }
            }
            .padding()
            Button {
                if emailInDatabase(email: username) {
                    let canLogin = validatePassword(username, password)
                    print(canLogin)
                }
//                    let user = getUser(username)
//                    if let userPassword = user?.password {
//                        if validatePassword(email: username, password: userPassword) {
//                            print("Can Login")
//                        }
//                        print(userPassword)
//                        if userPassword == password {
//                            print("Passwords Match")
//                        } else {
//                            print("Passwords do not match")
//                        }
//                    } else {
//                        print("userPassword could not be found")
//                    }
//                } else {
//                    print("user is not found")
//                }
            } label: {
                Text("Login")
            }

        }
        .frame(width: screenWidth * 0.8)
    }
}

struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
