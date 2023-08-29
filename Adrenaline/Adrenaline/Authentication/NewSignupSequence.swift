//
//  NewSignupSequence.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI
import Amplify

extension Formatter {
    static let heightFtFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 1
        return formatter
    }()
    
    static let heightInFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 2
        return formatter
    }()
    
    static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 3
        return formatter
    }()
    
    static let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 4
        return formatter
    }()
    
    static let ageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 2
        return formatter
    }()
}

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
    @State var heightFeet: Int = 0
    @State var heightInches: Int = 0
    @State var weight: Int = 0
    @State var weightUnit: WeightUnit = .lb
    @State var weightUnitString: String = ""
    @State var gender: Gender = .male
    @State var genderString: String = ""
    @State var age: Int = 0
    @State var gradYear: Int = 0
    @State var highSchool: String = ""
    @State var hometown: String = ""
    
    // Measurement Variables
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    // Formatting
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
            HStack {
                TextField("Height (ft)", value: $heightFeet, formatter: .heightFtFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .customField(icon: "hexagon.fill")
                    .focused($isFirstFocused)
                    .onChange(of: heightFeet) { _ in
                        heightFeet = heightFeet
                    }
                TextField("Height (in)", value: $heightInches, formatter: .heightInFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .customField(icon: "hexagon.fill")
                    .focused($isFirstFocused)
                    .onChange(of: heightInches) { _ in
                        heightInches = heightInches
                    }
            }
            
            HStack {
                TextField("Weight", value: $weight, formatter: .weightFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .customField(icon: "hexagon.fill")
                    .focused($isLastFocused)
                
                BubbleSelectView(selection: $weightUnit)
                    .frame(width: textFieldWidth / 2, height: screenHeight * 0.02)
                    .scaleEffect(1.08)
                    .onAppear {
                        weightUnitString = weightUnit.rawValue
                    }
                    .onChange(of: weightUnit) { _ in
                        weightUnitString = weightUnit.rawValue
                    }
            }
            
            HStack {
                TextField("Age", value: $age, formatter: .ageFormatter)
                    .keyboardType(.numberPad)
                    .customField(icon: "hexagon.fill")
                    .focused($isPhoneFocused)
                    .onChange(of: age) { _ in
                        age = age
                    }
                
                BubbleSelectView(selection: $gender)
                    .frame(width: textFieldWidth / 2)
                    .scaleEffect(1.05)
                    .onAppear {
                        genderString = gender.rawValue
                    }
                    .onChange(of: gender) { _ in
                        genderString = gender.rawValue
                    }
            }
            
            TextField("Graduation Year", value: $gradYear, formatter: .yearFormatter)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "hexagon.fill")
                .focused($isFirstFocused)
                .onChange(of: gradYear) { _ in
                    gradYear = gradYear
                }
            
            TextField("High School", text: $highSchool)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "hexagon.fill")
                .focused($isFirstFocused)
                .onChange(of: highSchool) { _ in
                    highSchool = highSchool
                }
            
            TextField("Hometown", text: $hometown)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .customField(icon: "hexagon.fill")
                .focused($isFirstFocused)
                .onChange(of: hometown) { _ in
                    hometown = hometown
                }
            
            Divider()
            
            Button {
                Task {
                    withAnimation(.openCard) {
                        print("Selected Next")
                        pageIndex = 1
                    }
                    
                    do {
                        guard let savedUser = savedUser else { return }
                        
                        // Create or retrieve the team and college items
                        let team = NewTeam(name: "DEFAULT")
                        let savedTeam = try await Amplify.DataStore.save(team)
                        
                        let college = College(name: "DEFAULT", imageLink: "")
                        let savedCollege = try await Amplify.DataStore.save(college)
                        
                        // Create the athlete item using the saved user, team, and college
                        let athlete = NewAthlete(
                            user: savedUser,
                            team: savedTeam, // Assign the saved team
                            college: savedCollege, // Assign the saved college
                            heightFeet: heightFeet,
                            heightInches: heightInches,
                            weight: weight,
                            weightUnit: weightUnitString,
                            gender: genderString,
                            age: age,
                            graduationYear: gradYear,
                            highSchool: highSchool,
                            hometown: hometown)
                        
                        // Save the athlete item
                        let savedItem = try await Amplify.DataStore.save(athlete)
                        print("Saved item: \(savedItem)")
                    } catch let error as DataStoreError {
                        print("Error creating item: \(error)")
                    } catch {
                        print("Unexpected error: \(error)")
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
