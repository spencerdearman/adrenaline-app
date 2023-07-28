//
//  LoginPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/27/23.
//

import SwiftUI
import LocalAuthentication

struct LoginPage: View {
    @Environment(\.getUser) private var getUser
    @Environment(\.validatePassword) private var validatePassword
    @State var isPasswordVisible: Bool = false
    @State var email: String = ""
    @State var password: String = ""
    @State var loginData: LoginData = LoginData()
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private func emailInDatabase(email: String) -> Bool {
        return getUser(email) != nil
    }
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .textContentType(.newPassword)
                .multilineTextAlignment(.center)
                .padding()
                .onChange(of: email) { _ in
                    loginData.username = email
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
                if emailInDatabase(email: email) {
                    let canLogin = validatePassword(email, password)
                    print(canLogin)
                }
            } label: {
                Text("Login")
            }

        }
        .frame(width: screenWidth * 0.8)
    }
}

enum AdrenalineLoginField: Int, Hashable, CaseIterable {
    case username
    case password
}

private func checkFields(divemeetsID: String = "",
                         password: String = "") -> Bool {
    return divemeetsID != "" && password != ""
}

struct AdrenalineSearchView: View {
    @Environment(\.colorScheme) var currentMode
    @State var showError: Bool = false
    @FocusState private var focusedField: LoginField?
    @State var progressView = true
    @Binding var createdKey: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var parsedUserHTML: String
    @Binding var loginSearchSubmitted: Bool
    @Binding var loginAttempted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var loggedIn: Bool
    @Binding var timedOut: Bool
    @Binding var showSplash: Bool
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
                                .frame(height: loginSuccessful ? geometry.size.height * 0.7 : geometry.size.height)
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
                                          ? geometry.size.width * 0.6
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
                                          ? geometry.size.width * 0.65
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
                        LoginProfile(
                            link: "https://secure.meetcontrol.com/divemeets/system/profile.php?number="
                            + divemeetsID, diverID: divemeetsID, loggedIn: $loggedIn,
                            divemeetsID: $divemeetsID, password: $password,
                            searchSubmitted: $searchSubmitted, loginSuccessful: $loginSuccessful,
                            loginSearchSubmitted: $loginSearchSubmitted)
                        .zIndex(1)
                        .onAppear {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    } else {
                        LoginPageSearchView(showError: $showError, divemeetsID: $divemeetsID,
                                            password: $password, searchSubmitted: $searchSubmitted,
                                            loginAttempted: $loginAttempted,
                                            loginSuccessful: $loginSuccessful,
                                            progressView: $progressView,
                                            timedOut: $timedOut, showSplash: $showSplash,
                                            focusedField: $focusedField)
                        .ignoresSafeArea(.keyboard)
                        .overlay{
                            VStack{}
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Button(action: previous) {
                                            Image(systemName: "chevron.up")
                                        }
                                        .disabled(hasReachedStart)
                                        
                                        Button(action: next) {
                                            Image(systemName: "chevron.down")
                                        }
                                        .disabled(hasReachedEnd)
                                        
                                        Spacer()
                                        
                                        Button(action: dismissKeyboard) {
                                            Text("**Done**")
                                        }
                                    }
                                }
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


struct LoginPageSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State var signupData = SignupData()
    @State var loginData = LoginData()
    @Binding var showError: Bool
    @Binding var divemeetsID: String
    @Binding var password: String
    @Binding var searchSubmitted: Bool
    @Binding var loginAttempted: Bool
    @Binding var loginSuccessful: Bool
    @Binding var progressView: Bool
    @Binding var timedOut: Bool
    @Binding var showSplash: Bool
    @State private var isPasswordVisible = false
    fileprivate var focusedField: FocusState<LoginField?>.Binding
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 50
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let cornerRadius: CGFloat = 50
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var errorMessage: Bool {
        loginAttempted && !loginSuccessful && !timedOut
    }
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    private let failTimeout: Double = 3
    
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
                    Text("DiveMeets ID:")
                        .padding(.leading)
                    TextField("DiveMeets ID", text: $divemeetsID)
                        .modifier(LoginTextFieldClearButton(text: $divemeetsID,
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
                    // Need to initially set search to false so webView gets recreated
                    searchSubmitted = false
                    loginAttempted = false
                    timedOut = false
                    focusedField.wrappedValue = nil
                    // Only submits a search if one of the relevant fields is filled,
                    // otherwise toggles error
                    if checkFields(divemeetsID: divemeetsID,
                                   password: password) {
                        showError = false
                        searchSubmitted = true
                    } else {
                        showError = true
                        searchSubmitted = false
                    }
                }, label: {
                    Text("Submit")
                        .foregroundColor(.primary)
                        .animation(nil)
                })
                .buttonStyle(.bordered)
                .cornerRadius(cornerRadius)
                if (searchSubmitted && !loginSuccessful) {
                    VStack {
                        if !errorMessage && !timedOut {
                            ProgressView()
                        }
                    }
                    
                    VStack {
                        if errorMessage && !timedOut {
                            Text("Login unsuccessful, please try again")
                                .scaledToFit()
                                .dynamicTypeSize(.xSmall ... .xxxLarge)
                                .lineLimit(2)
                        } else if timedOut {
                            Text("Unable to log in, network timed out")
                                .scaledToFit()
                                .dynamicTypeSize(.xSmall ... .xxxLarge)
                                .lineLimit(2)
                        } else {
                            Text("")
                        }
                    }
                }
                if showError {
                    Text("You must enter both fields to search")
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                        .foregroundColor(Color.red)
                    
                } else {
                    Text("")
                }
                
                NavigationLink(destination: AccountTypeSelectView(signupData: $signupData,
                                                                  showSplash: $showSplash)) {
                    Text("Create an account")
                }
                .cornerRadius(40)
                .foregroundColor(Custom.medBlue)
            }
            .onAppear {
                loginData.loadStoredCredentials()
                divemeetsID = ""
                password = ""
                
                if let username = loginData.username,
                   let password = loginData.password {
                    print("Username: \(username)")
                    print("Password: \(password)")
                }
            }
            .frame(width: screenWidth * 0.75)
            .padding(.bottom, maxHeightOffset)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
        }
        .offset(y: isPhone ? screenHeight * 0.1 : 0)
        .ignoresSafeArea(.keyboard)
    }
}



private extension LoginSearchInputView {
    var hasReachedStart: Bool {
        self.focusedField == LoginField.allCases.first
    }
    
    var hasReachedEnd: Bool {
        self.focusedField == LoginField.allCases.last
    }
    
    func dismissKeyboard() {
        self.focusedField = nil
    }
    
    func next() {
        guard let currentInput = focusedField,
              let lastIndex = LoginField.allCases.last?.rawValue else { return }
        
        let index = min(currentInput.rawValue + 1, lastIndex)
        self.focusedField = LoginField(rawValue: index)
    }
    
    func previous() {
        guard let currentInput = focusedField,
              let firstIndex = LoginField.allCases.first?.rawValue else { return }
        
        let index = max(currentInput.rawValue - 1, firstIndex)
        self.focusedField = LoginField(rawValue: index)
    }
}


struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
