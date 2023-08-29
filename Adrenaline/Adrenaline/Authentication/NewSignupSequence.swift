//
//  NewSignupSequence.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI

struct NewSignupSequence: View {
    @Environment(\.colorScheme) var currentMode
    @Namespace var namespace
    @ScaledMetric var pickerFontSize: CGFloat = 18
    @State private var savedUser: NewUser? = nil
    @State var pageIndex: Int = 0
    @State var newUser: GraphUser = GraphUser(firstName: "", lastName: "", email: "", accountType: "")
    @State var appear = [false, false, false]
    @Binding var email: String
    
    // Variables for BasicInfo
    @FocusState var isFirstFocused: Bool
    @FocusState var isLastFocused: Bool
    @FocusState var isPhoneFocused: Bool
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var phone: String = ""
    
    // Variables for Recruiting
    @State var heightIndex: Int = 24
    @State var height: String = ""
    @State var weight: String = ""
    @State var weightUnit: WeightUnit = .lb
    @State var gender: Gender = .male
    @State var ageIndex: Int = 5
    @State var age: String = ""
    @State var gradYear: String = ""
    @State var highSchool: String = ""
    @State var hometown: String = ""
    
    // Measurement Variables
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
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
    
    private var heightStrings: [(String, String, String)] {
        var result: [(String, String, String)] = []
        
        for ft in 4..<8 {
            for inches in 0..<12 {
                result.append(("\(ft)-\(inches)", String(ft), String(inches)))
            }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
            
            Group {
                switch pageIndex {
                case 0:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Info")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        basicInfoForm.slideFadeIn(show: appear[2], offset: 10)
                    }
                    .matchedGeometryEffect(id: "form", in: namespace)
                case 1:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recruiting Info")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        athleteInfoForm.slideFadeIn(show: appear[2], offset: 10)
                    }
                    .matchedGeometryEffect(id: "form", in: namespace)
                default:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Basic Information")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        athleteInfoForm.slideFadeIn(show: appear[2], offset: 10)
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
                newUser.email = email
            }
            .frame(width: screenWidth * 0.9)
        }
    }
    
    var basicInfoForm: some View {
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
                    withAnimation {
                        print("Selected Next")
                        pageIndex = 1
                    }
                    
                    do {
                        let newUser = try await saveUser(user: newUser)
                        print("Saved New User")
                        savedUser = newUser
                    } catch {
                        print("Could not save user to DataStore: \(error)")
                    }
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
        }
    }
    
    var athleteInfoForm: some View {
        Group {
            
            BubbleSelectView(selection: $weightUnit)
                .frame(width: textFieldWidth / 2)
                .onChange(of: weightUnit) { _ in
            
                }
            
            ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .cornerRadius(30)
                .frame(width: screenWidth * 0.5, height: screenHeight * 0.1)
                HStack {
                    Text("Height")
                        .foregroundColor(.secondary)
                    
                    NoStickPicker(selection: $heightIndex,
                                  rowCount: heightStrings.count) { i in
                        let label = UILabel()
                        let (_, ft, inches) = heightStrings[i]
                        let string = "\(ft)\' \(inches)\""
                        label.attributedText = NSMutableAttributedString(
                            string: string)
                        label.font = UIFont.systemFont(ofSize: pickerFontSize)
                        label.sizeToFit()
                        label.layer.masksToBounds = true
                        return label
                    }
                                  .pickerStyle(.wheel)
                                  .frame(width: textFieldWidth / 2)
                                  .padding(.trailing)
//                                  .onChange(of: heightIndex) { _ in
//                                      setHeight()
//                                  }
//                                  .onAppear {
//                                      setHeight()
//                                  }
                }
                .padding([.leading, .trailing])
            }
            .frame(height: screenHeight * 0.1)
            
            TextField("Height", text: $firstName)
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
                    withAnimation(.openCard) {
                        print("Selected Next")
                        pageIndex = 1
                    }
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
            Text("**Previous**")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .onTapGesture {
                    withAnimation(.openCard) {
                        pageIndex = 0
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
//
//struct NewSignupSequence_Previews: PreviewProvider {
//    static var previews: some View {
//        NewSignupSequence()
//    }
//}
