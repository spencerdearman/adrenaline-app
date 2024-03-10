//
//  NewSignupSequence.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI
import Amplify
import PhotosUI

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

enum PageIndex: Int, CaseIterable {
    case accountType = 0
    case basicInfo = 1
    case diveMeetsLink = 2
    case athleteInfo = 3
    case photoId = 4
    case profilePic = 5
    case welcome = 6
}

struct NewSignupSequence: View {
    @EnvironmentObject private var appLogic: AppLogic
    @Environment(\.colorScheme) private var currentMode
    @Environment(\.newUsers) private var newUsers
    @AppStorage("authUserId") private var authUserId: String = ""
    @Namespace var namespace
    @ScaledMetric var pickerFontSize: CGFloat = 18
    
    // Key Bindings
    @Binding var signupCompleted: Bool
    @Binding var email: String
    
    // User States
    @State var savedUser: NewUser? = nil
    
    // General States
    @State var buttonPressed: Bool = false
    @State var pageIndex: PageIndex = .accountType
    @State var appear = [false, false, false]
    @State var selectedDict: [String: Bool] = [:]
    @State var selected: Bool = false
    
    // Variables for Account Type
    @State var accountType: String = ""
    
    // Variables for BasicInfo
    @FocusState private var focusedField: SignupInfoField?
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var phone: String = ""
    @State var diveMeetsID: String? = nil
    @State var userCreationSuccessful: Bool = false
    @State var showBasicError: Bool = false
    
    // Variables for DiveMeets
    @State var searchSubmitted: Bool = false
    @State private var parsedLinks: DiverProfileRecords = [:]
    @State private var dmSearchSubmitted: Bool = false
    @State private var linksParsed: Bool = false
    @State private var personTimedOut: Bool = false
    @State var sortedRecords: [(String, String)] = []
    //                                         [profileLink: hometown]
    @State private var sortedRecordsHometowns: [String: String] = [:]
    @State var showNoDiveMeetsIdError: Bool = false
    @State private var waitingForLoad: Bool = true
    
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
    @State var athleteCreationSuccessful: Bool = false
    @State var showAthleteError: Bool = false
    
    // Variables for Photo ID Upload
    @State private var selectedPhotoIdImage: PhotosPickerItem? = nil
    @State private var photoId: Image? = nil
    @State private var photoIdData: Data? = nil
    
    // Variables for Profile Picture Upload
    @State private var selectedProfilePicImage: PhotosPickerItem? = nil
    @State private var profilePic: Image? = nil
    @State private var profilePicData: Data? = nil
    @State private var identityVerificationFailed: Bool = false
    @State private var devSkipProfilePic: Bool = false
    
    // Measurement Variables
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private var noDiverSelected: Bool {
        !selectedDict.values.contains(true)
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
    
    private func getSortedRecords(_ records: DiverProfileRecords) -> [(String, String)] {
        var result: [(String, String)] = []
        for (key, value) in records {
            for link in value {
                result.append((key, link))
            }
        }
        
        return result.sorted(by: { $0.0 < $1.0 })
    }
    
    private func createNewUser() -> NewUser {
        let tokensList: [String]
        if let userToken = UserDefaults.standard.string(forKey: "userToken") {
            tokensList = [userToken]
        } else { tokensList = [] }
        return NewUser(id: authUserId, firstName: firstName,
                       lastName: lastName, email: email,
                       phone: phone == ""
                       ? nil
                       : removePhoneFormatting(string: phone),
                       diveMeetsID: diveMeetsID,
                       accountType: accountType,
                       tokens: tokensList)
    }
    
    // Saves new user with stored State data, and handles CoachUser creation if needed
    private func saveNewUser() async -> Bool {
        do {
            var user = createNewUser()
            savedUser = try await saveToDataStore(object: user)
            print("Saved New User")
            
            if accountType == "Coach" {
                let coach = CoachUser(user: savedUser)
                let savedCoach = try await Amplify.DataStore.save(coach)
                print("Saved Coach Profile \(savedCoach)")
                user.setCoach(savedCoach)
                user.newUserCoachId = savedCoach.id
            }
            
            savedUser = try await saveToDataStore(object: user)
            print("Updated New User")
            
            return true
        } catch {
            showBasicError = true
            print("Could not save user to DataStore: \(error)")
        }
        
        return false
    }
    
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "LoginBackground" : "LoginBackground-Dark")
                .scaleEffect(0.7)
                .onTapGesture {
                    focusedField = nil
                }
            
            Group {
                switch pageIndex {
                    case .accountType:
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Account Type")
                                .font(.largeTitle).bold()
                                .foregroundColor(.primary)
                                .slideFadeIn(show: appear[0], offset: 30)
                            
                            accountInfoForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .frame(height: screenHeight * 0.6)
                        .matchedGeometryEffect(id: "form1", in: namespace)
                    case .basicInfo:
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Basic Info")
                                .font(.largeTitle).bold()
                                .foregroundColor(.primary)
                                .slideFadeIn(show: appear[0], offset: 30)
                            
                            basicInfoForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .matchedGeometryEffect(id: "form1", in: namespace)
                    case .diveMeetsLink:
                        Group {
                            if searchSubmitted && !personTimedOut && !linksParsed {
                                ZStack {
                                    SwiftUIWebView(firstName: $firstName, lastName: $lastName,
                                                   parsedLinks: $parsedLinks,
                                                   dmSearchSubmitted: $dmSearchSubmitted,
                                                   linksParsed: $linksParsed,
                                                   timedOut: $personTimedOut)
                                    .opacity(0)
                                    VStack {
                                        Text("Searching")
                                            .font(.largeTitle).bold()
                                            .foregroundColor(.primary)
                                            .slideFadeIn(show: appear[0], offset: 30)
                                        ProgressView()
                                    }
                                }
                                .frame(height: screenHeight * 0.5)
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
                            dmSearchSubmitted = false
                            linksParsed = false
                        }
                    case .athleteInfo:
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Recruiting Info")
                                .font(.largeTitle).bold()
                                .foregroundColor(.primary)
                                .slideFadeIn(show: appear[0], offset: 30)
                            
                            athleteInfoForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .matchedGeometryEffect(id: "form", in: namespace)
                    case .photoId:
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Photo ID")
                                .font(.largeTitle).bold()
                                .foregroundColor(.primary)
                                .slideFadeIn(show: appear[0], offset: 30)
                            
                            photoIdUploadForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .matchedGeometryEffect(id: "form", in: namespace)
                    case .profilePic:
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Profile Picture")
                                .font(.largeTitle).bold()
                                .foregroundColor(.primary)
                                .slideFadeIn(show: appear[0], offset: 30)
                            
                            profilePicUploadForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .matchedGeometryEffect(id: "form", in: namespace)
                    case .welcome:
                        VStack(alignment: .leading, spacing: 20) {
                            if let savedUser = savedUser {
                                Text("Welcome to Adrenaline \(savedUser.firstName)!")
                                    .font(.largeTitle).bold()
                                    .foregroundColor(.primary)
                                    .slideFadeIn(show: appear[0], offset: 30)
                            }
                            
                            welcomeForm.slideFadeIn(show: appear[2], offset: 10)
                        }
                        .matchedGeometryEffect(id: "form", in: namespace)
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
    
    var accountAllFieldsFilled: Bool {
        accountType != ""
    }
    
    var accountInfoForm: some View {
        Group {
            Button {
                accountType = "Athlete"
            } label: {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(accountType == "Athlete" ? Color.secondary : .clear,
                                        lineWidth: 2)
                        )
                        .padding(5)
                    
                    VStack {
                        Text("Athlete")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                        Text("You are looking to follow the results of your sport and get noticed by college coaches")
                            .scaleEffect(0.7)
                    }
                    .frame(height: screenHeight * 0.15)
                }
            }
            .frame(height: screenHeight * 0.15)
            
            Button {
                accountType = "Coach"
            } label: {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(accountType == "Coach" ? Color.secondary : .clear,
                                        lineWidth: 2)
                        )
                        .padding(5)
                    
                    VStack {
                        Text("Coach")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                        Text("You are looking to follow the results of your sport and seek out athletes to bring to your program")
                            .scaleEffect(0.7)
                    }
                    .frame(height: screenHeight * 0.15)
                }
            }
            .frame(height: screenHeight * 0.15)
            
            Button {
                accountType = "Spectator"
            } label: {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(accountType == "Spectator" ? Color.secondary : .clear,
                                        lineWidth: 2)
                        )
                        .padding(5)
                    
                    VStack {
                        Text("Spectator")
                            .foregroundColor(.primary)
                            .font(.title2).fontWeight(.semibold)
                        Text("You are looking to follow the results of a sport without any interest in recruiting")
                            .scaleEffect(0.7)
                    }
                    .frame(width: screenWidth * 0.5)
                }
            }
            .frame(height: screenHeight * 0.15)
            
            Divider()
            
            Button {
                if accountAllFieldsFilled {
                    buttonPressed = false
                    
                    withAnimation(.openCard) {
                        pageIndex = .basicInfo
                    }
                } else {
                    buttonPressed = true
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
        }
    }
    
    // Phone can be empty since it is optional
    var basicAllFieldsFilled: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
    var basicInfoForm: some View {
        Group {
            TextField("First Name", text: $firstName)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && firstName.isEmpty
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .firstName)
                .textContentType(.givenName)
            
            TextField("Last Name", text: $lastName)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && lastName.isEmpty
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .lastName)
                .textContentType(.familyName)
            
            TextField("Phone Number", text: $phone)
                .keyboardType(.numberPad)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && phone.isEmpty
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .phone)
                .textContentType(.telephoneNumber)
                .onChange(of: phone) {
                    phone = formatPhoneString(string: phone)
                }
            
            Divider()
            
            Button {
                searchSubmitted = true
                if basicAllFieldsFilled {
                    buttonPressed = false
                    if accountType != "Spectator" {
                        withAnimation(.openCard) {
                            pageIndex = .diveMeetsLink
                        }
                    } else {
                        Task {
                            userCreationSuccessful = await saveNewUser()
                            
                            if userCreationSuccessful {
                                withAnimation(.openCard) {
                                    pageIndex = .welcome
                                }
                            }
                        }
                    }
                } else {
                    buttonPressed = true
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
        }
        .onAppear {
            Task {
                // Manually initiate sync so newUsers is updated for diveMeetsLink stage
                try await Amplify.DataStore.start()
            }
        }
    }
    
    var diveMeetsInfoForm: some View {
        Group {
            if waitingForLoad {
                VStack {
                    Text("Searching...")
                    ProgressView()
                }
                .foregroundColor(.primary)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
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
                                    diveMeetsID = String(value.components(separatedBy: "=").last ?? "")
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
                                                    .stroke(selectedDict[value] == true
                                                            ? Color.secondary
                                                            : .clear,
                                                            lineWidth: 2)
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
                                            VStack(alignment: .leading) {
                                                Text(key)
                                                    .foregroundColor(.primary)
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                
                                                if sortedRecords.count > 1,
                                                    let hometown = sortedRecordsHometowns[value] {
                                                    Text(hometown)
                                                        .foregroundColor(.secondary)
                                                        .font(.headline)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        showBasicError = false
                        Task {
                            // Save user and CoachUser if needed
                            userCreationSuccessful = await saveNewUser()
                            
                            // Advance to next stage
                            if userCreationSuccessful {
                                withAnimation {
                                    if accountType == "Athlete" {
                                        pageIndex = .athleteInfo
                                    } else if devSkipProfilePic {
                                        pageIndex = .welcome
                                    } else {
                                        pageIndex = .photoId
                                    }
                                }
                            }
                        }
                    } label: {
                        ColorfulButton(title: "Continue")
                    }
                    .disabled(noDiverSelected)
                    
                    if showBasicError {
                        Text("Error creating user profile, please check information")
                            .foregroundColor(.primary).fontWeight(.semibold)
                    } else if showNoDiveMeetsIdError {
                        Text("Your DiveMeets account could not be found because either your name is spelled incorrectly, or it is already in use by another account")
                            .foregroundColor(.primary).fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("**Previous**")
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.primary.opacity(0.7))
                            .accentColor(.primary.opacity(0.7))
                            .onTapGesture {
                                withAnimation(.openCard) {
                                    pageIndex = .basicInfo
                                    
                                    // Reset the DiveMeets ID Search
                                    searchSubmitted = false
                                }
                            }
                        
                        // Hide the skip button when failed to find DiveMeets ID since "Continue"
                        // button will do the same thing
                        if !showNoDiveMeetsIdError {
                            Spacer()
                            
                            Text("**Skip**")
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.primary.opacity(0.7))
                                .accentColor(.primary.opacity(0.7))
                                .onTapGesture {
                                    Task {
                                        // Change all account selections to false and reset
                                        // diveMeetsID before advancing
                                        selectedDict.keys.forEach {
                                            selectedDict[$0] = false
                                        }
                                        diveMeetsID = nil
                                        
                                        // Save user and CoachUser if needed
                                        userCreationSuccessful = await saveNewUser()
                                        
                                        // Advance to next stage
                                        if userCreationSuccessful {
                                            withAnimation(.openCard) {
                                                if accountType == "Athlete" {
                                                    pageIndex = .athleteInfo
                                                } else if accountType != "Spectator" {
                                                    pageIndex = .profilePic
                                                } else {
                                                    pageIndex = .welcome
                                                }
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                showNoDiveMeetsIdError = false
                
                // Wait for DataStore to be ready before trying to query diveMeetsIds
                while !appLogic.dataStoreReady {
                    waitingForLoad = true
                    try await Task.sleep(seconds: 0.5)
                }
                
                // Get all currently used DiveMeets IDs and don't show them to the user as available
                // options for their name
                // Note: presentDiveMeetsIds is based on newUsers, which pulls from DataStore and
                // the sleep above is waiting on the sync to complete
                sortedRecords = getSortedRecords(parsedLinks).filter {
                    guard let id = $1.split(separator: "=").last else { return false }
                    return !presentDiveMeetsIds.contains(String(id))
                }
                
                if sortedRecords.count == 0 {
                    showNoDiveMeetsIdError = true
                } else if sortedRecords.count > 1 {
                    sortedRecordsHometowns = await getRecordHometowns(records: sortedRecords)
                }
                
                waitingForLoad = false
            }
        }
    }
    
    var athleteAllFieldsFilled: Bool {
        heightFeet != 0 && heightInches != -1 && weight != 0 && age != 0 && gradYear != 0 &&
        !highSchool.isEmpty && !hometown.isEmpty
    }
    
    var athleteInfoForm: some View {
        Group {
            HStack {
                TextField("Height (ft)", value: $heightFeet, formatter: .heightFtFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: buttonPressed && heightFeet == 0
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .heightFeet)
                    .onChange(of: heightFeet) {
                        heightFeet = heightFeet
                    }
                TextField("Height (in)", value: $heightInches, formatter: .heightInFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: buttonPressed && heightInches == 0
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .heightInches)
                    .onChange(of: heightInches) {
                        heightInches = heightInches
                    }
            }
            HStack {
                TextField("Weight", value: $weight, formatter: .weightFormatter)
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: buttonPressed && weight == 0
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .weight)
                
                BubbleSelectView(selection: $weightUnit)
                    .frame(width: textFieldWidth / 2, height: screenHeight * 0.02)
                    .scaleEffect(1.08)
                    .onAppear {
                        weightUnitString = weightUnit.rawValue
                    }
                    .onChange(of: weightUnit) {
                        weightUnitString = weightUnit.rawValue
                    }
            }
            HStack {
                TextField("Age", value: $age, formatter: .ageFormatter)
                    .keyboardType(.numberPad)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: buttonPressed && age == 0
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .age)
                    .onChange(of: age) {
                        age = age
                    }
                
                BubbleSelectView(selection: $gender)
                    .frame(width: textFieldWidth / 2)
                    .scaleEffect(1.05)
                    .onAppear {
                        genderString = gender.rawValue
                    }
                    .onChange(of: gender) {
                        genderString = gender.rawValue
                    }
            }
            TextField("Graduation Year", value: $gradYear, formatter: .yearFormatter)
                .keyboardType(.numberPad)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && gradYear == 0
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .gradYear)
                .onChange(of: gradYear) {
                    gradYear = gradYear
                }
            TextField("High School", text: $highSchool)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && highSchool.isEmpty
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .highSchool)
                .onChange(of: highSchool) {
                    highSchool = highSchool
                }
            TextField("Hometown", text: $hometown)
                .disableAutocorrection(true)
                .modifier(TextFieldModifier(icon: "hexagon.fill",
                                            iconColor: buttonPressed && hometown.isEmpty
                                            ? Custom.error
                                            : nil))
                .focused($focusedField, equals: .hometown)
                .onChange(of: hometown) {
                    hometown = hometown
                }
            Divider()
            
            
            Button {
                withAnimation(.closeCard) {
                    showAthleteError = false
                }
                Task {
                    await saveNewAthlete()
                }
            } label: {
                ColorfulButton(title: "Continue")
            }
            if showAthleteError {
                Text("Error creating athlete profile, please check information")
                    .foregroundColor(.primary).fontWeight(.semibold)
            }
            
            Text("**Previous**")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary.opacity(0.7))
                .accentColor(.primary.opacity(0.7))
                .onTapGesture {
                    Task {
                        // If returning to DiveMeetsLink stage, clear the user's DiveMeets ID
                        // so the search succeeds
                        if var user = savedUser {
                            user.diveMeetsID = nil
                            savedUser = try await saveToDataStore(object: user)
                        }
                        
                        withAnimation(.openCard) {
                            pageIndex = .diveMeetsLink
                        }
                    }
                }
        }
    }
    
    var photoIdUploadForm: some View {
        Group {
            VStack {
                PhotosPicker(selection: $selectedPhotoIdImage, matching: .images) {
                    ZStack {
                        if let photoId = photoId {
                            photoId
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 7)
                        } else {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 48, weight: .bold))
                                
                                Text("Upload a Photo ID to verify your identity")
                                    .padding(.top)
                            }
                            .padding()
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 45)
                
                Divider()
                
                Button {
                    Task {
                        buttonPressed = true
                        
                        if let data = photoIdData,
                           let id = savedUser?.id,
                           let firstName = savedUser?.firstName,
                           let lastName = savedUser?.lastName,
                           let dateOfBirth = savedUser?.dateOfBirth {
                            try await uploadPhotoId(data: data,
                                                    userId: id,
                                                    firstName: firstName,
                                                    lastName: lastName,
                                                    dateOfBirth: dateOfBirth)
                        }
                        
                        withAnimation(.openCard) {
                            pageIndex = .profilePic
                        }
                        
                        buttonPressed = false
                    }
                } label: {
                    ColorfulButton(title: "Continue")
                }
                .disabled(photoIdData == nil)
                .padding(.bottom)
                
                Text("**Previous**")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        Task {
                            if let id = savedUser?.id,
                               let firstName = savedUser?.firstName,
                               let lastName = savedUser?.lastName,
                               let dateOfBirth = savedUser?.dateOfBirth {
                                do {
                                    try await deletePhotoId(userId: id, 
                                                            firstName: firstName,
                                                            lastName: lastName,
                                                            dateOfBirth: dateOfBirth)
                                } catch {
                                    print("Failed to delete photo ID")
                                }
                            }
                            
                            // If returning to DiveMeetsLink stage, clear the user's DiveMeets ID
                            // so the search succeeds
                            if accountType != "Athlete", var user = savedUser {
                                user.diveMeetsID = nil
                                savedUser = try await saveToDataStore(object: user)
                            }
                            
                            withAnimation(.openCard) {
                                if accountType == "Athlete" {
                                    pageIndex = .athleteInfo
                                } else {
                                    pageIndex = .diveMeetsLink
                                }
                            }
                        }
                    }
            }
            .onChange(of: selectedPhotoIdImage) {
                Task {
                    guard let selectedImage = selectedPhotoIdImage else { return }
                    
                    // Load Picker image into Image
                    let _ = loadPhotoIdTransferable(from: selectedImage)
                    
                    // Load Picker image into Data
                    if let data = try? await selectedImage.loadTransferable(type: Data.self) {
                        photoIdData = data
                    }
                }
            }
            .onAppear {
                buttonPressed = false
            }
        }
    }
    
    var profilePicUploadForm: some View {
        Group {
            VStack {
                PhotosPicker(selection: $selectedProfilePicImage, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        if let profilePic = profilePic {
                            profilePic
                                .resizable()
                                .scaledToFit()
                                .frame(width:170, height:300)
                                .clipShape(Circle())
                                .overlay {
                                    Circle().stroke(.ultraThinMaterial, lineWidth: 15)
                                }
                                .shadow(radius: 7)
                                .frame(width: 200, height: 130)
                                .scaleEffect(0.9)
                        } else {
                            ProfileImage(profilePicURL: "")
                                .frame(width: 200, height: 130)
                                .scaleEffect(0.9)
                        }
                        
                        Image(systemName: "plus")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .background(.gray)
                            .clipShape(Circle())
                            .offset(x: -20, y: 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 45)
                
                if identityVerificationFailed {
                    Text("Failed to verify your identity. Make sure your face is visible in your profile picture and matches your photo ID")
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if buttonPressed {
                    VStack {
                        Text("Verifying your identity")
                            .foregroundColor(.primary)
                        ProgressView()
                    }
                    .padding()
                }
                
                Divider()
                
                Button {
                    Task {
                        buttonPressed = true
                        identityVerificationFailed = false
                        
                        if let data = profilePicData,
                           let id = savedUser?.id,
                           let firstName = savedUser?.firstName,
                           let lastName = savedUser?.lastName,
                           let dateOfBirth = savedUser?.dateOfBirth {
                            try await uploadProfilePictureForReview(data: data,
                                                                    userId: id,
                                                                    firstName: firstName,
                                                                    lastName: lastName, 
                                                                    dateOfBirth: dateOfBirth)
                            try await Task.sleep(seconds: 10)
                        }
                        
                        if let id = savedUser?.id, await hasProfilePicture(userId: id) {
                            withAnimation(.openCard) {
                                pageIndex = .welcome
                            }
                        } else {
                            identityVerificationFailed = true
                        }
                        
                        buttonPressed = false
                    }
                } label: {
                    ColorfulButton(title: "Continue")
                }
                .disabled(profilePicData == nil || buttonPressed)
                .padding(.bottom)
                
                Text("**Previous**")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        withAnimation(.openCard) {
                            pageIndex = .photoId
                        }
                    }
            }
            .onChange(of: selectedProfilePicImage) {
                Task {
                    guard let selectedImage = selectedProfilePicImage else { return }
                    
                    // Load Picker image into Image
                    let _ = loadProfilePicTransferable(from: selectedImage)
                    
                    // Load Picker image into Data
                    if let data = try? await selectedImage.loadTransferable(type: Data.self) {
                        profilePicData = data
                    }
                }
            }
            .onAppear {
                buttonPressed = false
            }
        }
    }
    
    var welcomeForm: some View {
        Group {
            Button {
                withAnimation(.closeCard) {
                    signupCompleted = true
                }
            } label: {
                ColorfulButton(title: "Take me to my profile")
            }
        }
    }
    
    var presentDiveMeetsIds: Set<String> {
        newUsers.reduce(into: Set<String>()) { (result, user) in
            if let id = user.diveMeetsID {
                result.insert(id)
            }
        }
    }
    
    private func loadPhotoIdTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard selectedPhotoIdImage == self.selectedPhotoIdImage else { return }
                switch result {
                    case .success(let image?):
                        // Handle the success case with the image.
                        photoId = image
                    case .success(nil):
                        // Handle the success case with an empty value.
                        photoId = nil
                    case .failure(let error):
                        // Handle the failure case with the provided error.
                        print("Failed to get image from picker: \(error)")
                        photoId = nil
                }
            }
        }
    }
    
    private func loadProfilePicTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard selectedProfilePicImage == self.selectedProfilePicImage else { return }
                switch result {
                    case .success(let image?):
                        // Handle the success case with the image.
                        profilePic = image
                    case .success(nil):
                        // Handle the success case with an empty value.
                        profilePic = nil
                    case .failure(let error):
                        // Handle the failure case with the provided error.
                        print("Failed to get image from picker: \(error)")
                        profilePic = nil
                }
            }
        }
    }
    
    // Get hometowns from profiles in sortedRecords to provide more info when there are multiple
    // accounts with the same name
    private func getRecordHometowns(records: [(String, String)]) async -> [String: String] {
        var result: [String: String] = [:]
        
        for (_, link) in records {
            let p = ProfileParser()
            if await !p.parseProfile(link: link) { continue }
            guard let hometown = p.profileData.info?.cityState else { continue }
            
            // Use link as key since records share the same name
            result[link] = hometown
        }
        
        return result
    }
    
    func saveNewAthlete() async {
        do {
            guard var user = savedUser else { return }
            print("Printing the saved User: \(user)")
            
            var springboard: Double? = nil
            var platform: Double? = nil
            var total: Double? = nil
            
            if let diveMeetsId = user.diveMeetsID {
                let parser = ProfileParser()
                if await !parser.parseProfile(diveMeetsID: diveMeetsId) {
                    return
                }
                
                if let stats = parser.profileData.diveStatistics {
                    let skillRating = SkillRating(diveStatistics: stats)
                    
                    (springboard, platform, total) =
                    await skillRating.getSkillRating(diveMeetsID: diveMeetsId)
                }
            }
            
            // Create the athlete item using the saved user, team, and college
            let athlete = NewAthlete(
                user: user,
                // TODO: save academics field
                heightFeet: heightFeet,
                heightInches: Int(heightInches),
                weight: weight,
                weightUnit: weightUnitString,
                gender: genderString,
                age: age,
                // TODO: add date of birth in YYYY-MM-dd format
                dateOfBirth: try Temporal.Date(iso8601String: ""),
                graduationYear: gradYear,
                highSchool: highSchool,
                hometown: hometown,
                springboardRating: springboard,
                platformRating: platform,
                totalRating: total)
            
            // Save the athlete item
            let savedItem = try await Amplify.DataStore.save(athlete)
            
            user.setAthlete(savedItem)
            user.newUserAthleteId = savedItem.id
            savedUser = try await saveToDataStore(object: user)
            
            withAnimation(.openCard) {
                athleteCreationSuccessful = true
            }
            print("Saved item: \(savedItem)")
        } catch let error as DataStoreError {
            withAnimation(.closeCard) {
                athleteCreationSuccessful = false
            }
            print("Error creating item: \(error)")
        } catch {
            withAnimation(.closeCard) {
                athleteCreationSuccessful = false
            }
            print("Unexpected error: \(error)")
        }
        withAnimation(.openCard) {
            if athleteAllFieldsFilled {
                if athleteCreationSuccessful {
                    buttonPressed = false
                    if devSkipProfilePic {
                        pageIndex = .welcome
                    } else {
                        pageIndex = .photoId
                    }
                } else {
                    showAthleteError = true
                }
            } else {
                buttonPressed = true
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
