//
//  BasicInfoView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

enum BasicInfoField: Int, Hashable, CaseIterable {
    case first
    case last
    case email
    case phone
    case password
    case repeatPassword
}

struct BasicInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.getUser) private var getUser
    @Environment(\.addUser) private var addUser
    @Environment(\.addAthlete) private var addAthlete
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var isEmailTaken: Bool = false
    @State private var emailSearched: Bool = false
    @State private var phone: String = ""
    @State var searchSubmitted: Bool = false
    @State private var password: String = ""
    @State private var repeatPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @Binding var signupData: SignupData
    @Binding var showSplash: Bool
    @FocusState private var focusedField: BasicInfoField?
    
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private var isNextDisabled: Bool {
        firstName == "" || lastName == "" || email == "" || isEmailTaken ||
        (phone != "" && phone.count != 14) || password == "" || password != repeatPassword
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private func removePhoneFormatting(string: String) -> String {
        return string.filter { $0.isNumber }
    }
    
    private func formatPhoneString(string: String) -> String {
        // (123) 456-7890
        // 12345678901234
        
        var chars = removePhoneFormatting(string: string)
        if chars.count > 0 {
            chars = "(" + chars
        }
        if chars.count > 4 {
            chars.insert(")", at: chars.index(chars.startIndex, offsetBy: 4))
            chars.insert(" ", at: chars.index(chars.startIndex, offsetBy: 5))
        }
        if chars.count > 9 {
            chars.insert("-", at: chars.index(chars.startIndex, offsetBy: 9))
        }
        
        return String(chars.prefix(14))
    }
    
    private func emailInDatabase(email: String) -> Bool {
        return getUser(email) != nil
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack {
                Spacer()
                
                BackgroundBubble(onTapGesture: { focusedField = nil }) {
                    VStack(spacing: 5) {
                        Text("Basic Information")
                            .font(.title2)
                            .bold()
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        TextField("First Name", text: $firstName)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .textContentType(.givenName)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .first)
                            .onChange(of: firstName) { _ in
                                signupData.firstName = firstName
                            }
                        TextField("Last Name", text: $lastName)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .textContentType(.familyName)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .last)
                            .onChange(of: lastName) { _ in
                                signupData.lastName = lastName
                            }
                        VStack {
                            TextField("Email", text: $email)
                                .autocapitalization(.none)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .email)
                                .onChange(of: email) { _ in
                                    signupData.email = email
                                }
                            // Only updates the changed email boolean if the user leaves email focus
                                .onChange(of: focusedField) { [focusedField] newValue in
                                    if focusedField == .email && newValue != .email {
                                        isEmailTaken = emailInDatabase(email: email)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.red, lineWidth: isEmailTaken ? 1 : 0)
                                )
                            if isEmailTaken {
                                Text("Email already in use")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        TextField("Phone (optional)", text: $phone)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .phone)
                            .onChange(of: phone) { _ in
                                phone = formatPhoneString(string: phone)
                                signupData.phone = removePhoneFormatting(string: phone)
                            }
                        
                        Spacer()
                        
                        VStack {
                            HStack {
                                (isPasswordVisible
                                 ? AnyView(TextField("Password", text: $password))
                                 : AnyView(SecureField("Password", text: $password)))
                                .disableAutocorrection(true)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .password)
                                .onChange(of: password) { _ in
                                    signupData.password = password
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
                            
                            HStack {
                                (isPasswordVisible
                                 ? AnyView(TextField("Retype password", text: $repeatPassword))
                                 : AnyView(SecureField("Retype password", text: $repeatPassword)))
                                .disableAutocorrection(true)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .repeatPassword)
                                Image(systemName: "eye.circle")
                                    .opacity(0.0)
                            }
                        }
                        .frame(width: textFieldWidth)
                        
                        Spacer()
                        NavigationLink(destination: DiveMeetsConnectorView(
                            searchSubmitted: $searchSubmitted, firstName: $firstName,
                            lastName: $lastName, signupData: $signupData,
                            showSplash: $showSplash)) {
                                Text("Next")
                                    .bold()
                            }
                            .simultaneousGesture(TapGesture().onEnded{
                                print("Coming in here")
                                focusedField = nil
                                searchSubmitted = true
                                if signupData.accountType == .athlete {
                                    addAthlete(firstName, lastName,
                                               email, phone, password)
                                } else {
                                    addUser(firstName, lastName,
                                            email, phone, password)
                                }
                            })
                            .buttonStyle(.bordered)
                            .cornerRadius(40)
                            .foregroundColor(.primary)
                            .opacity(isNextDisabled ? 0.5 : 1.0)
                            .disabled(isNextDisabled)
                    }
                    .frame(width: textFieldWidth)
                    .padding()
                }
                .frame(height: 300)
                .onAppear {
                    firstName = ""
                    lastName = ""
                    email = ""
                    phone = ""
                    password = ""
                    repeatPassword = ""
                    // Clears recruiting data on appear and if user comes back from recruiting
                    // section into basic info
                    signupData.recruiting = nil
                }
                .onDisappear {
                    print(signupData)
                    signupData.save()
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Signup")
                    .font(.title)
                    .bold()
            }
        }
    }
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView(signupData: .constant(SignupData()),
                      showSplash: .constant(true))
    }
}
