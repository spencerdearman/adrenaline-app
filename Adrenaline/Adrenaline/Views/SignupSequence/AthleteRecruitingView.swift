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
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var height: String = "4-0"
    @State private var weight: String = ""
    @State private var weightUnit: WeightUnit = .lb
    @State private var gender: Gender = .male
    @State private var age: String = ""
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
    
    private var requiredFieldsFilledIn: Bool {
        heightFeet != "" && heightInches != "" && weight != "" && age != "" && gradYear != "" &&
        highSchool != "" && hometown != ""
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
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack {
                Text("Signup")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                ZStack {
                    Rectangle()
                        .foregroundColor(Custom.grayThinMaterial)
                        .mask(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 6)
                        .onTapGesture {
                            focusedField = nil
                        }
                    
                    VStack(spacing: 10) {
                        Text("Recruiting Information")
                            .font(.title2)
                            .bold()
                            .padding()
                        Spacer()
                        
                        ZStack {
                            Rectangle()
                                .foregroundColor(Custom.grayThinMaterial)
                                .mask(RoundedRectangle(cornerRadius: 40))
                                .shadow(radius: 6)
                                .onTapGesture {
                                    focusedField = nil
                                }
                            
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
                                    let heightSplit = height.components(separatedBy: "-")
                                    
                                    if let ft = heightSplit.first,
                                       let inches = heightSplit.last,
                                       let ftInt = Int(ft),
                                       let inchInt = Int(inches) {
                                        if signupData.recruiting == nil {
                                            signupData.recruiting = RecruitingData()
                                        }
                                        signupData.recruiting!.height = Height(feet: ftInt,
                                                                               inches: inchInt)
                                    }
                                }
                            }
                        }
                        .frame(width: textFieldWidth, height: screenHeight * 0.1)
                        .padding(.bottom, 5)
                        
                        HStack {
                            TextField("Weight", text: $weight)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: textFieldWidth / 2)
                                .textContentType(.givenName)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .weight)
                                .onChange(of: weight) { _ in
                                    if signupData.recruiting == nil {
                                        signupData.recruiting = RecruitingData()
                                    }
                                    if let weight = Double(weight) {
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
                                    if let weight = Double(weight) {
                                        signupData.recruiting!.weight = Weight(weight: weight,
                                                                               unit: weightUnit)
                                    }
                                    print(signupData.recruiting!)
                                }
                        }
                        BubbleSelectView(selection: $gender)
                            .frame(width: textFieldWidth)
                            .onChange(of: gender) { _ in
                                if signupData.recruiting == nil {
                                    signupData.recruiting = RecruitingData()
                                }
                                signupData.recruiting!.gender = gender.rawValue
                                print(signupData.recruiting!)
                            }
                        
                        Spacer()
                        
                        NavigationLink(destination: ProfileView(profileLink: "")) {
                            Text("Next")
                                .bold()
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(40)
                        .foregroundColor(.primary)
                        .opacity(!requiredFieldsFilledIn ? 0.5 : 1.0)
                        .disabled(!requiredFieldsFilledIn)
                    }
                    .padding()
                }
                .frame(width: screenWidth * 0.9, height: 300)
                .onDisappear {
                    print(signupData)
                }
                
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

struct AthleteRecruitingView_Previews: PreviewProvider {
    static var previews: some View {
        AthleteRecruitingView(signupData: .constant(SignupData()))
    }
}
