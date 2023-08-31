//
//  LoginPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/27/23.
//

import SwiftUI
import LocalAuthentication

enum LoginField: Int, Hashable, CaseIterable {
    case email
    case passwd
}

private func checkFields(divemeetsID: String = "", password: String = "") -> Bool {
    return divemeetsID != "" && password != ""
}

//struct AdrenalineLoginView: View {
//    @Environment(\.colorScheme) var currentMode
//    @Environment(\.getUser) private var getUser
//    @Environment(\.validatePassword) private var validatePassword
//    @Environment(\.getAthlete) private var getAthlete
//    @Environment(\.networkIsConnected) private var networkIsConnected
//    @State var showError: Bool = false
//    @FocusState private var focusedField: LoginField?
//    @State var isPasswordVisible: Bool = false
//    @State var email: String = ""
//    @State var password: String = ""
//    @State var loginSuccessful: Bool = false
//    @Binding var showSplash: Bool
//    var showBackButton: Bool = false
//    private let cornerRadius: CGFloat = 30
//
//    private var isPhone: Bool {
//        UIDevice.current.userInterfaceIdiom != .pad
//    }
//    private var isLandscape: Bool {
//        let deviceOrientation = UIDevice.current.orientation
//        return deviceOrientation.isLandscape
//    }
//
//    var body: some View {
//        if networkIsConnected {
//            Group {
//                if showBackButton {
//                    LoginPage(showError: $showError, isPasswordVisible: $isPasswordVisible,
//                              email: $email, password: $password, loginSuccessful: $loginSuccessful,
//                              showSplash: $showSplash, showBackButton: true)
//                } else {
//                    NavigationView {
//                        LoginPage(showError: $showError, isPasswordVisible: $isPasswordVisible,
//                                  email: $email, password: $password, loginSuccessful: $loginSuccessful,
//                                  showSplash: $showSplash)
//                    }
//                    // Bless the person that figured this out:
//                    // https://developer.apple.com/forums/thread/693137
//                    .navigationViewStyle(.stack)
//                }
//            }
//            // Clears email and password on Logout press back to this page
//            .onChange(of: loginSuccessful) { newValue in
//                if !loginSuccessful {
//                    email = ""
//                    password = ""
//                }
//            }
//            // Gets stored credentials and automatically signs in the user
//            .onAppear {
//                if let creds = getStoredCredentials() {
//                    print(creds)
//                    withAnimation {
//                        loginSuccessful = true
//                        email = creds.0
//                    }
//                }
//            }
//        } else {
//            NotConnectedView()
//        }
//    }
//}

//struct LoginPage: View {
//    @Environment(\.colorScheme) var currentMode
//    @Environment(\.getUser) private var getUser
//    @Environment(\.validatePassword) private var validatePassword
//    @Environment(\.getAthlete) private var getAthlete
//    @Binding var showError: Bool
//    @FocusState private var focusedField: LoginField?
//    @Binding var isPasswordVisible: Bool
//    @Binding var email: String
//    @Binding var password: String
//    @Binding var loginSuccessful: Bool
//    @Binding var showSplash: Bool
//    var showBackButton: Bool = false
//    private let cornerRadius: CGFloat = 30
//
//    private var isPhone: Bool {
//        UIDevice.current.userInterfaceIdiom != .pad
//    }
//    private var isLandscape: Bool {
//        let deviceOrientation = UIDevice.current.orientation
//        return deviceOrientation.isLandscape
//    }
//
//    var body: some View {
//        ZStack {
//            (currentMode == .light ? Color.white : Color.black)
//                .ignoresSafeArea()
//            // Allows the user to hide the keyboard when clicking on the background of the page
//                .onTapGesture {
//                    focusedField = nil
//                }
//
//            ZStack {
//                VStack {
//                    if loginSuccessful {
//                        AdrenalineProfileView(userEmail: email,
//                                              loginSuccessful: $loginSuccessful)
//                        .zIndex(1)
//                        .onAppear {
//                            withAnimation {
//                                showSplash = false
//                            }
//                        }
//                    } else {
//                        if showBackButton {
//                            LoginContent(email: $email, password: $password,
//                                         loginSuccessful: $loginSuccessful,
//                                         showSplash: $showSplash, showBackButton: true,
//                                         focusedField: $focusedField)
//                        } else {
//                            LoginContent(email: $email, password: $password,
//                                         loginSuccessful: $loginSuccessful,
//                                         showSplash: $showSplash, focusedField: $focusedField)
//                        }
//                    }
//                }
//            }
//            .dynamicTypeSize(.xSmall ... .xxxLarge)
//        }
//        .onAppear {
//            showError = false
//        }
//    }
//}


//struct LoginContent: View {
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.getUser) private var getUser
//    @Environment(\.validatePassword) private var validatePassword
//    @Environment(\.getAthlete) private var getAthlete
//    @State var isPasswordVisible: Bool = false
//    @State var signupData: SignupData = SignupData()
//    @Binding var email: String
//    @Binding var password: String
//    @Binding var loginSuccessful: Bool
//    @Binding var showSplash: Bool
//    var showBackButton: Bool = false
//    fileprivate var focusedField: FocusState<LoginField?>.Binding
//    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
//    private let screenWidth = UIScreen.main.bounds.width
//    private let screenHeight = UIScreen.main.bounds.height
//    private let cornerRadius: CGFloat = 50
//    private var maxHeightOffset: CGFloat {
//        min(maxHeightOffsetScaled, 90)
//    }
//    private func emailInDatabase(email: String) -> Bool {
//        return getUser(email) != nil
//    }
//    
//    private var isPhone: Bool {
//        UIDevice.current.userInterfaceIdiom != .pad
//    }
//    
//    var body: some View {
//        BackgroundBubble() {
//            VStack{
//                VStack{
//                    Text("Login")
//                        .foregroundColor(.primary)
//                        .padding(.top)
//                }
//                .alignmentGuide(.leading) { _ in
//                    -screenWidth / 2 // Align the text to the leading edge of the screen
//                }
//                .bold()
//                .font(.title)
//                .padding()
//                HStack {
//                    Text("Email:")
//                        .padding(.leading)
//                    TextField("Email", text: $email)
//                        .modifier(TextFieldClearButton<LoginField>(text: $email,
//                                                                   fieldType: .email,
//                                                                   focusedField: focusedField))
//                        .textContentType(.emailAddress)
//                        .keyboardType(.emailAddress)
//                        .autocapitalization(.none)
//                        .disableAutocorrection(true)
//                        .textFieldStyle(.roundedBorder)
//                        .focused(focusedField, equals: .email)
//                    Image(systemName: "eye.circle")
//                        .opacity(0.0)
//                        .padding(.trailing)
//                }
//                HStack {
//                    Text("Password:")
//                        .padding(.leading)
//                    if isPasswordVisible {
//                        TextField("Password", text: $password)
//                            .modifier(TextFieldClearButton<LoginField>(text: $password,
//                                                                       fieldType: .passwd,
//                                                                       focusedField: focusedField))
//                            .textContentType(.password)
//                            .autocapitalization(.none)
//                            .disableAutocorrection(true)
//                            .keyboardType(.default)
//                            .textFieldStyle(.roundedBorder)
//                            .focused(focusedField, equals: .passwd)
//                    } else {
//                        SecureField("Password", text: $password)
//                            .modifier(TextFieldClearButton<LoginField>(text: $password,
//                                                                       fieldType: .passwd,
//                                                                       focusedField: focusedField))
//                            .textFieldStyle(.roundedBorder)
//                            .disableAutocorrection(true)
//                            .autocapitalization(.none)
//                            .focused(focusedField, equals: .passwd)
//                    }
//                    Button(action: {
//                        isPasswordVisible.toggle()
//                    }) {
//                        Image(systemName: isPasswordVisible ? "eye.circle" : "eye.slash.circle")
//                            .foregroundColor(.gray)
//                    }
//                    .padding(.trailing)
//                }
//                
//                Button(action: {
//                    loginSuccessful = false
//                    if let _ = getUser(email), validatePassword(email, password) {
//                        withAnimation {
//                            loginSuccessful = true
//                            saveCredentials(email: email, password: password)
//                        }
//                    } else {
//                        print("Failed to log in")
//                    }
//                }, label: {
//                    Text("Submit")
//                        .foregroundColor(.primary)
//                        .animation(nil)
//                })
//                .buttonStyle(.bordered)
//                .cornerRadius(cornerRadius)
//                NavigationLink(destination: AccountTypeSelectView(signupData: $signupData,
//                                                                  showSplash: $showSplash)) {
//                    Text("Create an account")
//                }
//                                                                  .cornerRadius(40)
//                                                                  .foregroundColor(Custom.medBlue)
//            }
//            .frame(width: screenWidth * 0.75)
//            .padding(.bottom, maxHeightOffset)
//        }
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            if showBackButton {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: { dismiss() }) {
//                        NavigationViewBackButton()
//                    }
//                }
//            }
//        }
//        .offset(y: isPhone ? screenHeight * 0.1 : 0)
//        .ignoresSafeArea(.keyboard)
//    }
//}
