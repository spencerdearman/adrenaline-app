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
        formatter.maximum = 7
        return formatter
    }()
    
    static let heightInFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.negativeInfinitySymbol = ""
        formatter.maximum = 11
        return formatter
    }()
    
    static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 500
        return formatter
    }()
    
    static let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 2999
        return formatter
    }()
    
    static let ageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        formatter.maximum = 99
        return formatter
    }()
}

struct ButtonInfo: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    var selected: Bool = false
}

struct NewSignupSequence: View {
    @Environment(\.colorScheme) var currentMode
    @Namespace var namespace
    @ScaledMetric var pickerFontSize: CGFloat = 18
    @State var signupCompleted: Bool = false
    @State var buttonPressed: Bool = false
    @State private var savedUser: NewUser? = nil
    @State var pageIndex: Int = 0
    @State var newUser: GraphUser = GraphUser(firstName: "", lastName: "", email: "", accountType: "")
    @State var appear = [false, false, false]
    @Binding var email: String
    @State var selectedDict: [String: Bool] = [:]
    @State var selected: Bool = false
    
    // Variables for BasicInfo
    @FocusState var isFirstFocused: Bool
    @FocusState var isLastFocused: Bool
    @FocusState var isPhoneFocused: Bool
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var phone: String = ""
    
    // Variables for DiveMeets
    @State var searchSubmitted: Bool = false
    @State private var parsedLinks: DiverProfileRecords = [:]
    @State private var dmSearchSubmitted: Bool = false
    @State private var linksParsed: Bool = false
    @State private var personTimedOut: Bool = false
    @State var sortedRecords: [(String, String)] = []
    
    // Variables for Recruiting
    @State var heightFeet: Int = 0
    @State var heightInches: Double = -.infinity
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
    
    // Converts keys and lists of values into tuples of key and value
    private func getSortedRecords(_ records: DiverProfileRecords) -> [(String, String)] {
        var result: [(String, String)] = []
        for (key, value) in records {
            for link in value {
                result.append((key, link))
            }
        }
        
        return result.sorted(by: { $0.0 < $1.0 })
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
                    .matchedGeometryEffect(id: "form1", in: namespace)
                case 1:
                    Group {
                        if searchSubmitted && !personTimedOut && !linksParsed {
                            ZStack {
                                SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                                               parsedLinks: $parsedLinks, dmSearchSubmitted: $dmSearchSubmitted,
                                               linksParsed: $linksParsed, timedOut: $personTimedOut)
                                VStack(alignment: .leading, spacing: 20) {
                                    if currentMode == .light {
                                        Image("LoginBackground")
                                    } else {
                                        Image("LoginBackground-Dark")
                                    }
                                    Text("Loading...")
                                        .font(.largeTitle).bold()
                                        .foregroundColor(.primary)
                                        .slideFadeIn(show: appear[0], offset: 30)
                                }
                            }
                        } else {
                            if linksParsed || personTimedOut {
                                VStack(alignment: .leading, spacing: 20) {
                                    diveMeetsInfoForm.slideFadeIn(show: appear[2], offset: 10)
                                }
                                .frame(height: screenHeight * 0.5)
                                .matchedGeometryEffect(id: "form", in: namespace)
                            } else {
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Searching")
                                        .font(.largeTitle).bold()
                                        .foregroundColor(.primary)
                                        .slideFadeIn(show: appear[0], offset: 30)
                                }
                                .matchedGeometryEffect(id: "form", in: namespace)
                            }
                        }
                    }
                    .onDisappear {
                        searchSubmitted = false
                    }
                case 2:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recruiting Info")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        athleteInfoForm.slideFadeIn(show: appear[2], offset: 10)
                    }
                    .matchedGeometryEffect(id: "form", in: namespace)
                case 3:
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Welcome to Adrenaline!")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                            .slideFadeIn(show: appear[0], offset: 30)
                        
                        welcomeForm.slideFadeIn(show: appear[2], offset: 10)
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
    
    var basicAllFieldsFilled: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !phone.isEmpty
    }
    
    var basicInfoForm: some View {
        Group {
            TextField("First Name", text: $firstName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && firstName.isEmpty ? Custom.error : nil))
                .focused($isFirstFocused)
                .onChange(of: firstName) { _ in
                    firstName = firstName
                    newUser.firstName = firstName
                }
            
            TextField("Last Name", text: $lastName)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && lastName.isEmpty ? Custom.error : nil))
                .focused($isLastFocused)
                .onChange(of: lastName) { _ in
                    lastName = lastName
                    newUser.lastName = lastName
                }
            
            TextField("Phone Number", text: $phone)
                .keyboardType(.numberPad)
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && phone.isEmpty ? Custom.error : nil))
                .focused($isPhoneFocused)
                .onChange(of: phone) { _ in
                    phone = formatPhoneString(string: phone)
                    newUser.phone = removePhoneFormatting(string: phone)
                }
            
            Divider()
            
            Button {
                searchSubmitted = true
                if basicAllFieldsFilled {
                    buttonPressed = false
                    pageIndex = 1
                } else {
                    buttonPressed = true
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
        }
    }
    
    var diveMeetsInfoForm: some View {
        Group {
            if sortedRecords.count == 1 {
                Text("Is this you?")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                    .slideFadeIn(show: appear[0], offset: 30)
            } else if sortedRecords.count > 1 {
                Text("Are you one of these profiles?")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                    .slideFadeIn(show: appear[0], offset: 30)
            } else {
                Text("No DiveMeets Profile Found")
                    .font(.largeTitle).bold()
                    .foregroundColor(.primary)
                    .slideFadeIn(show: appear[0], offset: 30)
            }
            if sortedRecords.count >= 1 {
                ScrollView {
                    ForEach(sortedRecords, id: \.1) { record in
                        let (key, value) = record
                        Button {
                            selectedDict[value] = true
                            newUser.diveMeetsID = String(value.components(separatedBy: "=").last ?? "")
                        } label: {
                            ZStack {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .cornerRadius(30)
                                    .onAppear {
                                        selectedDict[value] = false
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(selectedDict[value] == true ? Color.secondary : .clear, lineWidth: 2)
                                    )
                                    .padding(5)
                                
                                HStack {
                                    Spacer()
                                    ProfileImage(
                                        diverID: String(value
                                            .components(separatedBy: "=").last ?? ""))
                                    .scaleEffect(0.4)
                                    .frame(width: 100, height: 100)
                                    Spacer()
                                    Text(key)
                                        .foregroundColor(.primary)
                                        .font(.title2).fontWeight(.semibold)
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button {
                Task {
                    withAnimation {
                        print("Selected Next")
                        pageIndex = 2
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
            
            HStack {
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
                
                Spacer()
                
                Text("**Skip**")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        Task {
                            withAnimation {
                                print("Selected Next")
                                pageIndex = 2
                            }
                            do {
                                let newUser = try await saveUser(user: newUser)
                                print("Saved New User")
                                savedUser = newUser
                            } catch {
                                print("Could not save user to DataStore: \(error)")
                            }
                        }
                        withAnimation(.openCard) {
                            pageIndex = 2
                        }
                    }
            }
            
        }
        .onAppear {
            sortedRecords = getSortedRecords(parsedLinks)
        }
    }
    
    var athleteAllFieldsFilled: Bool {
        heightFeet != 0 && heightInches != -1 && weight != 0 && age != 0 && gradYear != 0 && !highSchool.isEmpty && !hometown.isEmpty
    }
    
    var athleteInfoForm: some View {
        Group {
            HStack {
                TextField("Height (ft)", value: $heightFeet, formatter: .heightFtFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && heightFeet == 0 ? Custom.error : nil))
                    .focused($isFirstFocused)
                    .onChange(of: heightFeet) { _ in
                        heightFeet = heightFeet
                    }
                TextField("Height (in)", value: $heightInches, formatter: .heightInFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && heightInches == 0 ? Custom.error : nil))
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
                    .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && weight == 0 ? Custom.error : nil))
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
                    .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && age == 0 ? Custom.error : nil))
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
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && gradYear == 0 ? Custom.error : nil))
                .focused($isFirstFocused)
                .onChange(of: gradYear) { _ in
                    gradYear = gradYear
                }
            
            TextField("High School", text: $highSchool)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && highSchool.isEmpty ? Custom.error : nil))
                .focused($isFirstFocused)
                .onChange(of: highSchool) { _ in
                    highSchool = highSchool
                }
            
            TextField("Hometown", text: $hometown)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill", iconColor: buttonPressed && hometown.isEmpty ? Custom.error : nil))
                .focused($isFirstFocused)
                .onChange(of: hometown) { _ in
                    hometown = hometown
                }
            
            Divider()
            
            Button {
                Task {
                    withAnimation(.openCard) {
                        if athleteAllFieldsFilled {
                            buttonPressed = false
                            pageIndex = 3
                        } else {
                            buttonPressed = true
                        }
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
                            heightInches: Int(heightInches),
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
                        pageIndex = 1
                    }
                }
        }
    }
    
    var welcomeForm: some View {
        Group {
            Button {
                signupCompleted = true
            } label: {
                ColorfulButton(title: "Take me to my profile")
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
