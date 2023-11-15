//
//  ConfirmPasswordReset.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/1/23.
//

import SwiftUI
import Authenticator

struct ConfirmPasswordReset: View {
    @Environment(\.colorScheme) var currentMode
    @ObservedObject var state: ConfirmResetPasswordState
    @State var appear = [false, false, false]
    @FocusState private var focusedField: SignupInfoField?
    @Binding var signupCompleted: Bool
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
                Text("Reset Password")
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
            TextField("Verification Code", text: $state.confirmationCode)
                .customField(icon: "envelope.open.fill")
                .autocapitalization(.none)
                .focused($focusedField, equals: .confirmationCode)
            
            SecureField("New Password", text: $state.newPassword)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "key.fill")
                .focused($focusedField, equals: .password)

            SecureField("Confirm Password", text: $state.confirmPassword)
                .textContentType(.password)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "key.fill")
                .focused($focusedField, equals: .confirmPassword)

            Button {
                Task {
                    try await state.confirmResetPassword()
                    signupCompleted = true
                }
            } label: {
                ColorfulButton(title: "Submit")
            }
            
            if state.isBusy {
                ProgressView()
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
