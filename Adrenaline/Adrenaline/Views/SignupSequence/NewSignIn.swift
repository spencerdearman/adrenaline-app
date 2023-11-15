//
//  NewSignIn.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI
import Authenticator
import Amplify

struct NewSignIn: View {
    @Environment(\.colorScheme) private var currentMode
    @ObservedObject var state: SignInState
    @State private var username = ""
    @Binding var email: String
    @Binding var authUserId: String
    @Binding var signupCompleted: Bool
    @FocusState private var focusedField: SignupInfoField?
    @State private var appear = [false, false, false]
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Sign In")
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
            TextField("Email Address", text: $username)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .email)
                .customField(icon: "envelope.open.fill")
                .onChange(of: username) {
                    email = username
                }
            
            SecureField("Password", text: $state.password)
                .textContentType(.password)
                .customField(icon: "key.fill")
                .focused($focusedField, equals: .password)
            
            Button {
                state.username = email
                Task {
                    try? await state.signIn()
                    
                    let pred = NewUser.keys.email == email
                    let users = await queryAWSUsers(where: pred)
                    if users.count == 1 {
                        authUserId = users[0].id
                    }
                    
                    signupCompleted = true
                }
            } label: {
                ColorfulButton(title: "Sign In")
            }
            
            if state.isBusy {
                ProgressView()
            }
            
            Divider()
            
            HStack {
                Text("**Forgot Password?**")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        withAnimation {
                            state.move(to: .resetPassword)
                        }
                    }
                
                Spacer()
                
                Text("No account yet? **Sign Up**")
                    .font(.footnote)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        withAnimation {
                            state.move(to: .signUp)
                        }
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

struct CirclePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TextFieldModifier: ViewModifier {
    var icon: String
    var iconColor: Color? = nil
    
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack {
                    Image(systemName: icon)
                        .frame(width: 36, height: 36)
                        .foregroundColor(iconColor != nil 
                                         ? iconColor
                                         : .gray.opacity(0.5))
                        .background(.thinMaterial)
                        .cornerRadius(14)
                        .modifier(OutlineOverlay(cornerRadius: 14))
                        .offset(x: -46)
                        .foregroundStyle(.secondary)
                        .accessibility(hidden: true)
                    Spacer()
                }
            )
            .foregroundStyle(.primary)
            .padding(15)
            .padding(.leading, 40)
            .background(.thinMaterial)
            .cornerRadius(20)
            .modifier(OutlineOverlay(cornerRadius: 20))
    }
}

extension View {
    func customField(icon: String, iconColor: Color? = nil) -> some View {
            self.modifier(TextFieldModifier(icon: icon, iconColor: iconColor))
    }
}
