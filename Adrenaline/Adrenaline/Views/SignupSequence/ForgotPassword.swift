//
//  ForgotPassword.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/1/23.
//

import SwiftUI
import Authenticator

struct ForgotPassword: View {
    @Environment(\.colorScheme) var currentMode
    @ObservedObject var state: ResetPasswordState
    @State var appear = [false, false, false]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Forgot Password")
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
            TextField("Email", text: $state.username)
                .customField(icon: "envelope.open.fill")
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button {
                Task {
                    try? await state.resetPassword()
                }
            } label: {
                ColorfulButton(title: "Send Code")
            }
            
            if state.isBusy {
                ProgressView()
            }
            
            Divider()
            
            Text("Return to **Sign In**")
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
