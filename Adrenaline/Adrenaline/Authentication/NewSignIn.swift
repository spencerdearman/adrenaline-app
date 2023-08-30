//
//  NewSignIn.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI
import Authenticator

struct NewSignIn: View {
    @Environment(\.colorScheme) var currentMode
    @ObservedObject var state: SignInState
    @State var text = ""
    @State var password = ""
    @State var circleInitialY = CGFloat.zero
    @State var circleY = CGFloat.zero
    @State var displaySignIn: Bool = true
    @FocusState var isEmailFocused: Bool
    @FocusState var isPasswordFocused: Bool
    @State var appear = [false, false, false]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
            
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
            TextField("Email Address", text: $state.username)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isEmailFocused)
                .customField(icon: "envelope.open.fill")
            
            SecureField("Password", text: $state.password)
                .textContentType(.password)
                .customField(icon: "key.fill")
                .focused($isPasswordFocused)
            
            Button {
                Task {
                    try? await state.signIn()
                }
            } label: {
                ColorfulButton(title: "Sign In")
            }
            
            if state.isBusy {
                ProgressView()
            }
            
            Divider()
            
            Text("No account yet? **Sign Up**")
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .onTapGesture {
                    withAnimation {
                        displaySignIn = true
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

struct NewSignUp: View {
    @Environment(\.colorScheme) var currentMode
    @ObservedObject var state: SignUpState
    @State var text = ""
    @State var password = ""
    @State var circleInitialY = CGFloat.zero
    @State var circleY = CGFloat.zero
    @State var displaySignIn: Bool = true
    @FocusState var isEmailFocused: Bool
    @FocusState var isPasswordFocused: Bool
    @State var appear = [false, false, false]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)

            VStack(alignment: .leading, spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                    .slideFadeIn(show: appear[0], offset: 30)
                    .onAppear{
                        print(state.fields.self)
                    }

                //form.slideFadeIn(show: appear[2], offset: 10)
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

//    var form: some View {
//        Group {
//            TextField("Email Address", text: $state.fields.first(where: { $0.field.attributeType == .username })?.value ?? "")
//                .textContentType(.emailAddress)
//                .keyboardType(.emailAddress)
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .customField(icon: "envelope.open.fill")
//                .overlay(
//                    GeometryReader { proxy in
//                        let offset = proxy.frame(in: .named("stack")).minY + 32
//                        Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
//                    }
//                        .onPreferenceChange(CirclePreferenceKey.self) { value in
//                            circleInitialY = value
//                            circleY = value
//                        }
//                )
//                .focused($isEmailFocused)
//                .onChange(of: isEmailFocused) { isEmailFocused in
//                    if isEmailFocused {
//                        withAnimation {
//                            circleY = circleInitialY
//                        }
//                    }
//                }
//
//            SecureField("Password", text: $state.password)
//                .textContentType(.password)
//                .customField(icon: "key.fill")
//                .focused($isPasswordFocused)
//                .onChange(of: isPasswordFocused, perform: { isPasswordFocused in
//                    if isPasswordFocused {
//                        withAnimation {
//                            circleY = circleInitialY + 70
//                        }
//                    }
//                })
//
//            Button {
//                Task {
//                    try? await state.signIn()
//                }
//            } label: {
//                ColorfulButton(title: "Sign In")
//            }
//
//            if state.isBusy {
//                ProgressView()
//            }
//
//            Divider()
//
//            Text("No account yet? **Sign up**")
//                .font(.footnote)
//                .foregroundColor(.primary.opacity(0.7))
//                .accentColor(.primary.opacity(0.7))
//                .onTapGesture {
//                    withAnimation {
//                        displaySignIn = false
//                    }
//                }
//        }
//    }

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
                        .foregroundColor(iconColor != nil ? iconColor : .gray.opacity(0.5))
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
