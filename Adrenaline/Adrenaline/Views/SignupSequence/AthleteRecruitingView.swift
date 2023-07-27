//
//  AthleteRecruitingView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

enum RecruitingInfoField: Int, Hashable, CaseIterable {
    case height
    case weight
    case gender
    case age
    case gradYear
    case highSchool
    case hometown
}

enum WeightUnit: String, CaseIterable {
    case lb = "lb"
    case kg = "kg"
}

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

struct AthleteRecruitingView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.updateAthleteField) private var updateAthleteField
    @Environment(\.updateAthleteSkillRating) private var updateAthleteSkillRating
    // Starts the picker at height 6' 0"
    @State private var heightIndex: Int = 24
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var weightUnit: WeightUnit = .lb
    @State private var gender: Gender = .male
    // Starts the picker at age 18
    @State private var ageIndex: Int = 5
    @State private var age: String = ""
    @State private var gradYear: String = ""
    @State private var highSchool: String = ""
    @State private var hometown: String = ""
    @Binding var signupData: SignupData
    @Binding var diveMeetsID: String
    @FocusState private var focusedField: RecruitingInfoField?
    @ScaledMetric var pickerFontSize: CGFloat = 18
    // Parsing information
    @StateObject private var parser = ProfileParser()
    @State private var isExpanded: Bool = false
    private let getTextModel = GetTextAsyncModel()
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    // Verifies that weight and gradYear have appropriate values and high school and hometown
    // are not empty
    private var requiredFieldsFilledIn: Bool {
        weight.filter { $0.isNumber }.count > 0 &&
        gradYear.filter { $0.isNumber }.count > 0 && highSchool != "" && hometown != ""
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
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
    
    private let ageRange: [Int] = Array(13..<26)
    
    private func setHeight() {
        height = heightStrings[heightIndex].0
        let heightSplit = height.components(separatedBy: "-")
        
        if let ft = heightSplit.first,
           let inches = heightSplit.last,
           let ft = Int(ft),
           let inches = Int(inches) {
            if signupData.recruiting == nil {
                signupData.recruiting = RecruitingData()
            }
            signupData.recruiting!.height = Height(feet: ft,
                                                   inches: inches)
        }
    }
    
    private func setGender() {
        if signupData.recruiting == nil {
            signupData.recruiting = RecruitingData()
        }
        signupData.recruiting!.gender = gender.rawValue
    }
    
    private func setAge() {
        age = String(ageRange[ageIndex])
        if signupData.recruiting == nil {
            signupData.recruiting = RecruitingData()
        }
        signupData.recruiting!.age = ageRange[ageIndex]
    }
    
    private func setAthleteRecruitingFields() {
        guard let recruiting = signupData.recruiting else { return }
        guard let email = signupData.email else { return }
        var values: [String: Any?] = ["weightUnit": recruiting.weight?.unit.rawValue,
                                      "gender": gender.rawValue,
                                      "graduationYear": recruiting.gradYear,
                                      "hometown": recruiting.hometown]
        
        if let feet = recruiting.height?.feet {
            values["heightFeet"] = Int16(feet)
        }
        if let inches = recruiting.height?.inches {
            values["heightInches"] = Int16(inches)
        }
        if let weight = recruiting.weight?.weight {
            values["weight"] = Int16(weight)
        }
        if let age = recruiting.age {
            values["age"] = Int16(age)
        }
        
        for (key, value) in values {
            updateAthleteField(email, key, value)
        }
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            // Profile Information
            let infoSafe = parser.profileData.info != nil
            let info = parser.profileData.info
            let parsedCityState = info?.cityState
            let parsedGender = info?.gender
            let parsedAge = info?.age
            let parsedGradYear = info?.hsGradYear
            
            VStack {
                Spacer()
                Spacer()
                
                BackgroundBubble(shadow: 6, onTapGesture: { focusedField = nil }) {
                    VStack(spacing: 10) {
                        Text("Recruiting Information")
                            .font(.title2)
                            .bold()
                            .padding()
                        Spacer()
                        
                        VStack(spacing: 5) {
                            BackgroundBubble(shadow: 6, onTapGesture: { focusedField = nil }) {
                                HStack {
                                    Text("Height:")
                                    NoStickPicker(selection: $heightIndex,
                                                  rowCount: heightStrings.count) { i in
                                        let label = UILabel()
                                        let (_, ft, inches) = heightStrings[i]
                                        let string = "\(ft)\' \(inches)\""
                                        label.attributedText = NSMutableAttributedString(string: string)
                                        label.font = UIFont.systemFont(ofSize: pickerFontSize)
                                        label.sizeToFit()
                                        label.layer.masksToBounds = true
                                        return label
                                    }
                                                  .pickerStyle(.wheel)
                                                  .frame(width: textFieldWidth / 2)
                                                  .padding(.trailing)
                                                  .onChange(of: heightIndex) { _ in
                                                      setHeight()
                                                  }
                                                  .onAppear {
                                                      setHeight()
                                                  }
                                }
                                .padding([.leading, .trailing])
                            }
                            .frame(height: screenHeight * 0.1)
                            
                            Spacer()
                            
                            HStack {
                                TextField("Weight", text: $weight)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: textFieldWidth / 2)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .focused($focusedField, equals: .weight)
                                    .onChange(of: weight) { _ in
                                        weight = String(weight.prefix(6))
                                        
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        if let weight = Int(weight) {
                                            signupData.recruiting!.weight = Weight(weight: weight,
                                                                                   unit: weightUnit)
                                        }
                                    }
                                BubbleSelectView(selection: $weightUnit)
                                    .frame(width: textFieldWidth / 2)
                                    .onChange(of: weightUnit) { _ in
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        if let weight = Int(weight) {
                                            signupData.recruiting!.weight = Weight(weight: weight,
                                                                                   unit: weightUnit)
                                        }
                                    }
                            }
                            
                            if infoSafe, let parsedGender = parsedGender{
                                if parsedGender == "M" {
                                    Text("Gender: Male")
                                        .onAppear {
                                            if signupData.recruiting == nil {
                                                signupData.recruiting = RecruitingData()
                                            }
                                            signupData.recruiting!.gender = "Male"
                                        }
                                } else {
                                    Text("Gender: Female")
                                        .onAppear {
                                            if signupData.recruiting == nil {
                                                signupData.recruiting = RecruitingData()
                                            }
                                            signupData.recruiting!.gender = "Female"
                                        }
                                }
                            } else {
                                BubbleSelectView(selection: $gender)
                                    .frame(width: textFieldWidth)
                                    .onChange(of: gender) { _ in
                                        setGender()
                                    }
                                    .onAppear {
                                        setGender()
                                    }
                            }
                            
                            Spacer()
                            
                            BackgroundBubble(shadow: 6, onTapGesture: { focusedField = nil }) {
                                HStack {
                                    if infoSafe, let parsedAge = parsedAge {
                                        Text("Age: " + String(parsedAge))
                                            .onAppear {
                                                if signupData.recruiting == nil {
                                                    signupData.recruiting = RecruitingData()
                                                }
                                                signupData.recruiting!.age = parsedAge
                                            }
                                    } else {
                                        Text("Age:")
                                        NoStickPicker(selection: $ageIndex,
                                                      rowCount: ageRange.count) { i in
                                            let label = UILabel()
                                            let age = ageRange[i]
                                            label.attributedText = NSMutableAttributedString(string: String(age))
                                            label.font = UIFont.systemFont(ofSize: pickerFontSize)
                                            label.sizeToFit()
                                            label.layer.masksToBounds = true
                                            return label
                                        }
                                                      .pickerStyle(.wheel)
                                                      .frame(width: textFieldWidth / 2)
                                                      .padding(.trailing)
                                                      .onChange(of: ageIndex) { _ in
                                                          setAge()
                                                      }
                                                      .onAppear {
                                                          setAge()
                                                      }
                                    }
                                }
                                .padding([.leading, .trailing])
                            }
                            .frame(height: screenHeight * 0.1)
                            
                            Spacer()
                            
                            if infoSafe, let parsedGradYear = parsedGradYear {
                                Text("Graduation Year: " + String(parsedGradYear))
                                    .onAppear {
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        signupData.recruiting!.gradYear = parsedGradYear
                                    }
                            } else {
                                VStack(spacing: 10) {
                                    TextField("Graduation Year", text: $gradYear)
                                        .disableAutocorrection(true)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: textFieldWidth * 0.75)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .focused($focusedField, equals: .gradYear)
                                        .onChange(of: gradYear) { _ in
                                            gradYear = String(gradYear.prefix(4))
                                            
                                            if signupData.recruiting == nil {
                                                signupData.recruiting = RecruitingData()
                                            }
                                            if let gradYear = Int(gradYear) {
                                                signupData.recruiting!.gradYear = gradYear
                                            }
                                        }
                                }
                            }
                            
                            TextField("High School", text: $highSchool)
                                .disableAutocorrection(true)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .highSchool)
                                .onChange(of: highSchool) { _ in
                                    if signupData.recruiting == nil {
                                        signupData.recruiting = RecruitingData()
                                    }
                                    signupData.recruiting!.highSchool = highSchool
                                }
                            
                            if infoSafe, let parsedCityState = parsedCityState {
                                Text("Hometown: " + String(parsedCityState))
                                    .onAppear {
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        signupData.recruiting!.hometown = parsedCityState
                                    }
                            } else {
                                TextField("Hometown", text: $hometown)
                                    .disableAutocorrection(true)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: textFieldWidth)
                                    .multilineTextAlignment(.center)
                                    .focused($focusedField, equals: .hometown)
                                    .onChange(of: hometown) { _ in
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        signupData.recruiting!.hometown = hometown
                                    }
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            NavigationLink(destination: AdrenalineProfileView(
                                diveMeetsID: $diveMeetsID, signupData: $signupData)) {
                                Text("Skip")
                                    .bold()
                            }
                            .buttonStyle(.bordered)
                            .cornerRadius(40)
                            .foregroundColor(.secondary)
                            
                            NavigationLink(destination: AdrenalineProfileView(
                                diveMeetsID: $diveMeetsID, signupData: $signupData)) {
                                Text("Next")
                                    .bold()
                            }
                            .buttonStyle(.bordered)
                            .cornerRadius(40)
                            .foregroundColor(.primary)
                            .opacity(!requiredFieldsFilledIn ? 0.3 : 1.0)
                            .disabled(!requiredFieldsFilledIn)
                            .simultaneousGesture(TapGesture().onEnded {
                                setAthleteRecruitingFields()
                                guard let stats = parser.profileData.diveStatistics else { return }
                                let skill = SkillRating(diveStatistics: stats)
                                Task {
                                    let (springboard, platform, _) =
                                    await skill.getSkillRating(stats: stats,
                                                               metric: skill.computeMetric1)
                                    print(springboard, " - ", platform)
                                    guard let email = signupData.email else { return }
                                    updateAthleteSkillRating(email, springboard, platform)
                                }
                            })
                        }
                    }
                    .padding()
                }
                .frame(height: 300)
                .onDisappear {
                    print(signupData)
                }
                
                Spacer()
                Spacer()
                Spacer()
            }
        }
        .dynamicTypeSize(.xSmall ... .accessibility1)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Signup")
                    .font(.title)
                    .bold()
            }
        }
        .onAppear {
            Task {
                if diveMeetsID != "" && parser.profileData.info == nil {
                    if await !parser.parseProfile(link: "https://secure.meetcontrol.com/divemeets/system/profile.php?number=" + diveMeetsID) {
                        print("Failed to parse profile")
                    } else {
                        let info = parser.profileData.info
                        guard let g = info?.gender else { return }
                        gender = g == "M" ? .male : .female
                        guard let parsedAge = info?.age else { return }
                        age = String(parsedAge)
                        guard let parsedGradYear = info?.hsGradYear else { return }
                        gradYear = String(parsedGradYear)
                        guard let parsedHometown = info?.cityState else { return }
                        hometown = parsedHometown
                    }
                }
            }
        }
    }
}

struct BubbleSelectView<E: CaseIterable & Hashable & RawRepresentable>: View
where E.RawValue == String, E.AllCases: RandomAccessCollection {
    @Binding var selection: E
    
    
    private let cornerRadius: CGFloat = 30
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
            HStack(spacing: 0) {
                ForEach(E.allCases, id: \.self) { e in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge only
                        // when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(selection == e ? selectedGray : .clear)
                            .padding(.trailing, e == E.allCases.first ? cornerRadius : 0)
                            .padding(.leading, e == E.allCases.last ? cornerRadius : 0)
                            .cornerRadius(e == E.allCases.first || e == E.allCases.last
                                          ? cornerRadius : 0)
                            .padding(.trailing, e == E.allCases.first ? -cornerRadius : 0)
                            .padding(.leading, e == E.allCases.last ? -cornerRadius : 0)
                        Text(e.rawValue)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        selection = e
                    }
                    if e != E.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 30)
        .padding([.leading, .top, .bottom], 5)
    }
}
