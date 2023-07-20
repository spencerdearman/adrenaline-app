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
    @State private var height: String = "6-0"
    @State private var weight: String = ""
    @State private var weightUnit: WeightUnit = .lb
    @State private var gender: Gender = .male
    @State private var age: String = "18"
    @State private var gradYear: String = ""
    @State private var highSchool: String = ""
    @State private var hometown: String = ""
    @Binding var signupData: SignupData
    @FocusState private var focusedField: RecruitingInfoField?
    
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
    
    private func getHeightStrings() -> [(String, String, String)] {
        var result: [(String, String, String)] = []
        
        for ft in 4..<8 {
            for inches in 0..<12 {
                result.append(("\(ft)-\(inches)", String(ft), String(inches)))
            }
        }
        
        return result
    }
    
    private func setHeight() {
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
        if signupData.recruiting == nil {
            signupData.recruiting = RecruitingData()
        }
        if let age = Int(age) {
            signupData.recruiting!.age = age
        }
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
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
                                    Picker("", selection: $height) {
                                        ForEach(getHeightStrings(), id: \.0) { (tag, ft, inches) in
                                            Text("\(ft)\' \(inches)\"")
                                                .tag(tag)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: textFieldWidth / 2)
                                    .onChange(of: height) { _ in
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
                            
                            BubbleSelectView(selection: $gender)
                                .frame(width: textFieldWidth)
                                .onChange(of: gender) { _ in
                                    setGender()
                                }
                                .onAppear {
                                    setGender()
                                }
                            
                            Spacer()
                            
                            BackgroundBubble(shadow: 6, onTapGesture: { focusedField = nil }) {
                                HStack {
                                    Text("Age:")
                                    Picker("", selection: $age) {
                                        ForEach(13..<26, id: \.self) { age in
                                            Text("\(age)")
                                                .tag(String(age))
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: textFieldWidth / 2)
                                    .onChange(of: age) { _ in
                                        setAge()
                                    }
                                    .onAppear {
                                        setAge()
                                    }
                                }
                                .padding([.leading, .trailing])
                            }
                            .frame(height: screenHeight * 0.1)
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                TextField("Graduation Year", text: $gradYear)
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
                                
                                TextField("High School", text: $highSchool)
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
                                
                                TextField("Hometown", text: $hometown)
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
                            NavigationLink(destination: ProfileView(profileLink: "")) {
                                Text("Skip")
                                    .bold()
                            }
                            .buttonStyle(.bordered)
                            .cornerRadius(40)
                            .foregroundColor(.secondary)
                            
                            NavigationLink(destination: ProfileView(profileLink: "")) {
                                Text("Next")
                                    .bold()
                            }
                            .buttonStyle(.bordered)
                            .cornerRadius(40)
                            .foregroundColor(.primary)
                            .opacity(!requiredFieldsFilledIn ? 0.3 : 1.0)
                            .disabled(!requiredFieldsFilledIn)
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
