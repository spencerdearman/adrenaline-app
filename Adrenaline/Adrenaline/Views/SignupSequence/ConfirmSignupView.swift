//
//  ConfirmSignupView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/1/23.
//

import SwiftUI
import Authenticator

struct ConfirmSignUp: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.authenticatorState) var authenticatorState
    @ObservedObject var state: ConfirmSignUpState
    @Binding var email: String
    @State var appear = [false, false, false]
    @State var confirmationError = false
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
                animate()
                
            }
            .frame(width: screenWidth * 0.9)
        }
    }
    
    var form: some View {
        Group {
            TextField("Confirmation Code", text: $state.confirmationCode)
                .customField(icon: "envelope.open.fill")
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: .confirmationCode)
            
            Button {
                Task {
                    focusedField = nil
                    confirmationError = false
                    do {
                        try await state.confirmSignUp()
                    } catch {
                        confirmationError = true
                    }
                }
            } label: {
                ColorfulButton(title: "Confirm Email")
            }
            
            if state.isBusy {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if confirmationError {
                Text("Incorrect code, please try again")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Divider()
            
            Text("Code sent to \(email)")
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
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

