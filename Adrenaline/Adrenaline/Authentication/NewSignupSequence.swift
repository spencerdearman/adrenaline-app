//
//  NewSignupSequence.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI

struct NewSignupSequence: View {
    @Environment(\.colorScheme) var currentMode
    @State var pageIndex: Int = 0
    @State var newUser: GraphUser = GraphUser(firstName: "", lastName: "", email: "", accountType: "")
    @State var appear = [false, false, false]
    //@Binding var email: String
    
    //Variables for BasicInfo
    @FocusState var isFirstFocused: Bool
    @FocusState var isLastFocused: Bool
    @FocusState var isPhoneFocused: Bool
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var phone: String = ""
    
    // Measurement Variables
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private func removePhoneFormatting(string: String) -> String {
        return string.filter { $0.isNumber }
    }
    
    private func formatPhoneString(string: String) -> String {
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
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
            
            Group {
                switch pageIndex {
                case 0:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Information")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        form.slideFadeIn(show: appear[2], offset: 10)
                    }
                default:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Information")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                    
                        form.slideFadeIn(show: appear[2], offset: 10)
                    }
                }
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
            TextField("First Name", text: $firstName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "hexagon.fill")
                .focused($isFirstFocused)
                .onChange(of: firstName) { _ in
                    newUser.firstName = firstName
                }
            
            TextField("Last Name", text: $lastName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "hexagon.fill")
                .focused($isLastFocused)
                .onChange(of: lastName) { _ in
                    newUser.lastName = lastName
                }
            
            TextField("Phone Number", text: $phone)
                .keyboardType(.numberPad)
                .customField(icon: "hexagon.fill")
                .focused($isPhoneFocused)
                .onChange(of: phone) { _ in
                    phone = formatPhoneString(string: phone)
                    newUser.phone = removePhoneFormatting(string: phone)
                }
            
            Divider()
            
            Button {
                Task {
                    print("Selected Next")
                }
            } label: {
                ColorfulButton(title: "Continue")
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

struct NewSignupSequence_Previews: PreviewProvider {
    static var previews: some View {
        NewSignupSequence()
    }
}
