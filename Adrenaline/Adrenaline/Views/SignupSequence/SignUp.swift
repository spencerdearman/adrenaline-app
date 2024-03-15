//
//  SignUp.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/1/23.
//

import SwiftUI
import Amplify
import Authenticator

// https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
extension String {
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
}

struct SignUp: View {
    @Environment(\.colorScheme) var currentMode
    @ObservedObject var state: SignUpState
    @State var signUpErrorMessage: String = ""
    @State var signUpError: Bool = false
    @Binding var email: String
    @Binding var signupCompleted: Bool
    @State var appear = [false, false, false]
    @FocusState private var focusedField: SignupInfoField?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                    .slideFadeIn(show: appear[0], offset: 30)
                
                form.slideFadeIn(show: appear[2], offset: 10)
            }
            .padding(20)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .modifier(OutlineModifier(cornerRadius: 30))
            .onAppear {
                signupCompleted = false
                animate()
            }
            .frame(width: screenWidth * 0.9)
        }
    }
    
    var form: some View {
        Group {
            ForEach(state.fields, id: \.self) { field in
                SignUpField(email: $email, field, focusedField: $focusedField)
            }
            Button {
                focusedField = nil
                
                // Passwords match
                if !state.fields[0].value.isEmpty,
                   state.fields[1].value == state.fields[2].value, state.fields[1].value.count >= 8 {
                    Task {
                        signUpErrorMessage = ""
                        signUpError = false
                        do {
                            try await state.signUp()
                        } catch {
                            if state.fields[0].value.isValidEmail {
                                signUpErrorMessage = "Email already exists, please sign in"
                            } else {
                                signUpErrorMessage = "Email invalid, please try again"
                            }
                            signUpError = true
                        }
                    }
                } else if state.fields[1].value.count < 8 {
                    signUpErrorMessage = "Password must be at least 8 characters"
                    signUpError = true
                } else if state.fields[1].value != state.fields[2].value {
                    signUpErrorMessage = "Passwords do not match"
                    signUpError = true
                }
            } label: {
                ColorfulButton(title: "Sign Up")
            }
            
            if state.isBusy {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            if signUpError {
                Text(signUpErrorMessage)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Divider()
            
            Text("Already have an account? **Sign In**")
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .onTapGesture {
                    withAnimation {
                        state.move(to: .signIn)
                    }
                }
        }
    }
    
    func animate() {
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.2)) {
            appear[0] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.6)) {
            appear[2] = true
        }
    }
}

struct SignUpField: View {
    @ObservedObject private var signUpField: SignUpState.Field
    @Binding var email: String
    @State private var fieldValue: String = ""
    var focusedField: FocusState<SignupInfoField?>.Binding
    
    init(email: Binding<String>, _ signUpField: SignUpState.Field, focusedField: FocusState<SignupInfoField?>.Binding) {
        self._email = email
        self.signUpField = signUpField
        _fieldValue = State(initialValue: signUpField.value)
        self.focusedField = focusedField
    }
    
    var body: some View {
        switch signUpField.field.attributeType {
        case .email:
            TextField("Email", text: $fieldValue)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "envelope.open.fill")
                .focused(focusedField, equals: .email)
                .onChange(of: fieldValue) {
                    signUpField.value = fieldValue
                    email = fieldValue
                }
        case .password:
            SecureField("Password", text: $signUpField.value)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "key.fill")
                .focused(focusedField, equals: .password)
        case .passwordConfirmation:
            SecureField("Confirm password", text: $signUpField.value)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "key.fill")
                .focused(focusedField, equals: .confirmPassword)
        default:
            Text("Wrong Case")
        }
    }
}
