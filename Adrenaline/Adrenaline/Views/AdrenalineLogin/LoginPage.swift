//
//  LoginPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/27/23.
//

import SwiftUI
import LocalAuthentication

private func checkFields(divemeetsID: String = "",
                         password: String = "") -> Bool {
    return divemeetsID != "" && password != ""
}

struct AdrenalineSearchView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.getUser) private var getUser
    @Environment(\.validatePassword) private var validatePassword
    @Environment(\.getAthlete) private var getAthlete
    @State var showError: Bool = false
    @FocusState private var focusedField: LoginField?
    @State var isPasswordVisible: Bool = false
    @State var email: String = ""
    @State var password: String = ""
    @State var user: User = User()
    @State var athlete: Athlete = Athlete()
    @State var loginSuccessful: Bool = false
    @Binding var showSplash: Bool
    var showBackButton: Bool = false
    private let cornerRadius: CGFloat = 30
    
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    private var isLandscape: Bool {
        let deviceOrientation = UIDevice.current.orientation
        return deviceOrientation.isLandscape
    }
    
    var body: some View {
        if showBackButton {
            LoginContent(showError: $showError, isPasswordVisible: $isPasswordVisible, email: $email, password: $password, user: $user, athlete: $athlete, loginSuccessful: $loginSuccessful, showSplash: $showSplash, showBackButton: true)
        } else {
            NavigationView {
                LoginContent(showError: $showError, isPasswordVisible: $isPasswordVisible, email: $email, password: $password, user: $user, athlete: $athlete, loginSuccessful: $loginSuccessful, showSplash: $showSplash)
            }
        }
    }
}

struct LoginContent: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.getUser) private var getUser
    @Environment(\.validatePassword) private var validatePassword
    @Environment(\.getAthlete) private var getAthlete
    @Binding var showError: Bool
    @FocusState private var focusedField: LoginField?
    @Binding var isPasswordVisible: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var user: User
    @Binding var athlete: Athlete
    @Binding var loginSuccessful: Bool
    @Binding var showSplash: Bool
    var showBackButton: Bool = false
    private let cornerRadius: CGFloat = 30
    
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    private var isLandscape: Bool {
        let deviceOrientation = UIDevice.current.orientation
        return deviceOrientation.isLandscape
    }
    
    var body: some View {
            ZStack {
                (currentMode == .light ? Color.white : Color.black)
                    .ignoresSafeArea()
                // Allows the user to hide the keyboard when clicking on the background of the page
                    .onTapGesture {
                        focusedField = nil
                    }
                
                ZStack {
                    GeometryReader { geometry in
                        VStack {
                            ZStack{
                                Circle()
                                // Circle color
                                    .fill(Custom.darkBlue)
                                // Adjust the size of the circle as desired
                                    .frame(width: geometry.size.width * 2.5,
                                           height: geometry.size.width * 2.5)
                                // Center the circle
                                    .position(x: loginSuccessful
                                              ? geometry.size.width
                                              : geometry.size.width / 2,
                                              y: loginSuccessful || isPhone || !isLandscape
                                              ? -geometry.size.width * 0.55
                                              : -geometry.size.width * 0.85)
                                    .shadow(radius: 15)
                                    .frame(height: loginSuccessful ? geometry.size.height * 0.7 :
                                            geometry.size.height)
                                    .clipped().ignoresSafeArea()
                                Circle()
                                // Circle color
                                    .fill(Custom.coolBlue)
                                    .frame(width: loginSuccessful
                                           ? geometry.size.width * 1.3
                                           : geometry.size.width * 2.0,
                                           height: loginSuccessful
                                           ? geometry.size.width * 1.3
                                           : geometry.size.width * 2.0)
                                    .position(x: loginSuccessful
                                              ? geometry.size.width
                                              : geometry.size.width / 2,
                                              y: loginSuccessful
                                              ? geometry.size.width * 0.7
                                              : isPhone
                                              ? -geometry.size.width * 0.55
                                              : isLandscape
                                              ? -geometry.size.width * 0.75
                                              : -geometry.size.width * 0.55)
                                    .shadow(radius: 15)
                                    .frame(height: loginSuccessful ? geometry.size.height * 0.7 : geometry.size.height)
                                    .clipped().ignoresSafeArea()
                                Circle()
                                // Circle color
                                    .fill(Custom.medBlue)
                                    .frame(width: loginSuccessful
                                           ? geometry.size.width * 1.1
                                           : geometry.size.width * 1.5,
                                           height: loginSuccessful
                                           ? geometry.size.width * 1.1
                                           : geometry.size.width * 1.5)
                                    .position(x: loginSuccessful ? 0 : geometry.size.width / 2,
                                              y: loginSuccessful || (!isPhone && isLandscape)
                                              ? geometry.size.width * 0.7
                                              : -geometry.size.width * 0.55)
                                    .shadow(radius: 15)
                                    .frame(height: loginSuccessful
                                           ? geometry.size.height * 0.7
                                           : geometry.size.height)
                                    .clipped().ignoresSafeArea()
                            }
                        }
                    }
                    VStack {
                        if loginSuccessful {
                            AdrenalineProfileView(loggedIn: true, user: $user)
                            .zIndex(1)
                            .onAppear {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        } else {
                            if showBackButton {
                                LoginPage(email: $email, password: $password, user: $user,
                                          loginSuccessful: $loginSuccessful,
                                          showSplash: $showSplash, showBackButton: true, focusedField: $focusedField)
                            } else {
                                LoginPage(email: $email, password: $password, user: $user,
                                          loginSuccessful: $loginSuccessful,
                                          showSplash: $showSplash, focusedField: $focusedField)
                            }
                        }
                    }
                }
                .dynamicTypeSize(.xSmall ... .xxxLarge)
            }
            .onAppear {
                showError = false
        }
    }
}


struct LoginPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.getUser) private var getUser
    @Environment(\.validatePassword) private var validatePassword
    @Environment(\.getAthlete) private var getAthlete
    @State var isPasswordVisible: Bool = false
    @State var signupData: SignupData = SignupData()
    @Binding var email: String
    @Binding var password: String
    @Binding var user: User
    @Binding var loginSuccessful: Bool
    @Binding var showSplash: Bool
    var showBackButton: Bool = false
    fileprivate var focusedField: FocusState<LoginField?>.Binding
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let cornerRadius: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    private func emailInDatabase(email: String) -> Bool {
        return getUser(email) != nil
    }
    
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    var body: some View {
        BackgroundBubble() {
            VStack{
                VStack{
                    Text("Login")
                        .foregroundColor(.primary)
                        .padding(.top)
                }
                .alignmentGuide(.leading) { _ in
                    -screenWidth / 2 // Align the text to the leading edge of the screen
                }
                .bold()
                .font(.title)
                .padding()
                HStack {
                    Text("Email:")
                        .padding(.leading)
                    TextField("Email", text: $email)
                        .modifier(LoginTextFieldClearButton(text: $email,
                                                            fieldType: .diveMeetsId,
                                                            focusedField: focusedField))
                        .textContentType(.username)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .focused(focusedField, equals: .diveMeetsId)
                    Image(systemName: "eye.circle")
                        .opacity(0.0)
                        .padding(.trailing)
                }
                HStack {
                    Text("Password:")
                        .padding(.leading)
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .modifier(LoginTextFieldClearButton(text: $password,
                                                                fieldType: .passwd,
                                                                focusedField: focusedField))
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.default)
                            .textFieldStyle(.roundedBorder)
                            .focused(focusedField, equals: .passwd)
                    } else {
                        SecureField("Password", text: $password)
                            .modifier(LoginTextFieldClearButton(text: $password,
                                                                fieldType: .passwd,
                                                                focusedField: focusedField))
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .focused(focusedField, equals: .passwd)
                    }
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.circle" : "eye.slash.circle")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }
                
                Button(action: {
                    loginSuccessful = false
                    if emailInDatabase(email: email) {
                        let u = getUser(email)
                        user = u ?? User()
                        withAnimation {
                            loginSuccessful = true
                        }
                    }
                }, label: {
                    Text("Submit")
                        .foregroundColor(.primary)
                        .animation(nil)
                })
                .buttonStyle(.bordered)
                .cornerRadius(cornerRadius)
                NavigationLink(destination: AccountTypeSelectView(signupData: $signupData,
                                                                  showSplash: $showSplash)) {
                    Text("Create an account")
                }
                .cornerRadius(40)
                .foregroundColor(Custom.medBlue)
            }
            .frame(width: screenWidth * 0.75)
            .padding(.bottom, maxHeightOffset)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if showBackButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        NavigationViewBackButton()
                    }
                }
            }
        }
        .offset(y: isPhone ? screenHeight * 0.1 : 0)
        .ignoresSafeArea(.keyboard)
    }
}


//struct LoginPage_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginPage()
//    }
//}
