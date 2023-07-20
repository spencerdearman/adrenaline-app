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
}

struct BasicInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @Binding var signupData: SignupData
    @Binding var selectedOption: AccountType?
    @FocusState private var focusedField: BasicInfoField?
    
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private var requiredFieldsFilledIn: Bool {
        firstName != "" && lastName != "" && email != ""
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private func formatPhoneString(string: String) -> String {
        // (123) 456-7890
        // 12345678901234
        
        var chars = string.filter { $0.isNumber }
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
                            Spacer()
                            
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth)
                                .textContentType(.givenName)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .first)
                                .onChange(of: firstName) { _ in
                                    signupData.firstName = firstName
                                }
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth)
                                .textContentType(.familyName)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .last)
                                .onChange(of: lastName) { _ in
                                    signupData.lastName = lastName
                                }
                            TextField("Email", text: $email)
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
                            TextField("Phone (optional)", text: $phone)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .phone)
                                .onChange(of: phone) { _ in
                                    phone = formatPhoneString(string: phone)
                                    signupData.phone = phone
                                }
                            
                            Spacer()
                            
                            NavigationLink(destination: signupData.accountType == .athlete
                                           ? AnyView(AthleteRecruitingView(signupData: $signupData))
                                           : AnyView(ProfileView(profileLink: ""))) {
                                Text("Next")
                                    .bold()
                            }
                                           .buttonStyle(.bordered)
                                           .cornerRadius(40)
                                           .foregroundColor(.primary)
                                           .opacity(!requiredFieldsFilledIn ? 0.5 : 1.0)
                                           .disabled(!requiredFieldsFilledIn)
                        }
                        .padding()
                    }
                .frame(height: 300)
                .onAppear {
                    // Clears recruiting data on appear and if user comes back from recruiting
                    // section into basic info
                    signupData.recruiting = nil
                }
                .onDisappear {
                    print(signupData)
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
                                            selectedOption: .constant(nil))
    }
}
