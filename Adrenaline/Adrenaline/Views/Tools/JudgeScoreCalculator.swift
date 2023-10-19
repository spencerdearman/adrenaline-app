//
//  JudgeScoreCalculator.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/2/23.
//

import SwiftUI



struct JudgeScoreCalculator: View {
    @Environment(\.colorScheme) var currentMode
    @State var tableData: [String: DiveData]?
    @State var dive: String = ""
    @State var height: DiveHeight = .one
    @State var score: String = ""
    var focusedField: FocusState<JudgeScoreField?>.Binding
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let cornerRadius: CGFloat = 30
    private let shadowRadius: CGFloat = 5
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    private var heightDouble: Double {
        Double(String(height.rawValue.dropLast())) ?? 0.0
    }
    
    private var scoreDouble: Double? {
        if let res = Double(score) {
            return res
        }
        
        return nil
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private var name: String? {
        getDiveName(data: tableData ?? [:], forKey: dive)
    }
    
    private var dd: Double? {
        getDiveDD(data: tableData ?? [:], forKey: dive, height: heightDouble)
    }
    
    private var judgesScores: [String] {
        guard let total = scoreDouble else { return [] }
        guard let dd = dd else { return [] }
        let netRaw = total / dd
        let netInt = Double(Int(netRaw))
        let netRemainder = netRaw.truncatingRemainder(dividingBy: 1)
        let net: Double
        
        // Rounds up to nearest 0.5 so judge scores will always produce at least the desired score
        // total is evently divided by dd to nearest 0.5
        if netInt == netRaw || netRemainder == 0.5 {
            net = netRaw
            // total is between a whole and 0.5 on low end
        } else if netRemainder < 0.5 {
            net = netInt + 0.5
            // total is between a whole and 0.5 on high end
        } else {
            net = netInt + 1.0
        }
        
        let fractionalJudgeScore = net / 3.0
        let whole = Double(Int(fractionalJudgeScore))
        let wholePlusHalf = whole + 0.5
        let wholePlusOne = whole + 1.0
        let remainder = fractionalJudgeScore.truncatingRemainder(dividingBy: 1)
        var result: [Double] = []
        
        // Determines the judge scores required to sum to the net score
        if remainder == 0.0 || remainder == 0.5 {
            result = [fractionalJudgeScore, fractionalJudgeScore, fractionalJudgeScore]
        } else if remainder < 0.2 {
            result = [whole, whole, wholePlusHalf]
        } else if remainder < 0.4 {
            result = [whole, wholePlusHalf, wholePlusHalf]
        } else if remainder < 0.8 {
            result = [wholePlusHalf, wholePlusHalf, wholePlusOne]
        } else {
            result = [wholePlusHalf, wholePlusOne, wholePlusOne]
        }
        
        // Last value will always be >= other values, so if it exceeds 10.0, then score is too big
        if result.count > 2 && result.last! > 10.0 {
            return ["Not possible"]
        }
        
        return result.map { String($0) }
    }
    
    var body: some View {
        ZStack {
            Color.clear
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .mask(RoundedRectangle(cornerRadius: 50))
                    .frame(width: screenWidth * 0.9, height: screenHeight * 0.42)
                    .shadow(radius: shadowRadius)
                    .onTapGesture {
                        focusedField.wrappedValue = nil
                    }
                
                VStack(spacing: 5) {
                    
                    VStack(spacing: 20) {
                        Text("Judge Score Calculator")
                            .foregroundColor(.primary)
                            .font(.title2)
                            .bold()
                            .padding(.top, 30)
                            .dynamicTypeSize(.xSmall ... .xxxLarge)
                        
                        DiveHeightSelectView(height: $height)
                            .scaleEffect(0.9)
                        
                        HStack {
                            Spacer()
                            TextField("Number", text: $dive)
                                .textInputAutocapitalization(.characters)
                                .focused(focusedField, equals: .dive)
                                .frame(width: 150, height: 50)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Custom.darkGray))
                                .onChange(of: dive) {
                                    dive = String(dive.prefix(5))
                                }
                                .shadow(radius: shadowRadius)
                            Spacer()
                            TextField("Score", text: $score)
                                .keyboardType(.decimalPad)
                                .focused(focusedField, equals: .score)
                                .frame(width: 150, height: 50)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Custom.darkGray))
                                .shadow(radius: shadowRadius)
                                .onChange(of: score) {
                                    score = String(score.prefix(6))
                                }
                            Spacer()
                        }
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                        
                        if let name = name, let dd = dd {
                            VStack(spacing: 5) {
                                HStack(spacing: 0) {
                                    Text("Name: ")
                                        .bold()
                                    Text(name)
                                }
                                HStack(spacing: 0) {
                                    Text("DD: ")
                                        .bold()
                                    Text(String(dd))
                                }
                            }
                        }
                        
                        if name != nil, dd != nil, scoreDouble != nil {
                            BackgroundBubble(vPadding: 30, hPadding: 50) {
                                VStack(spacing: 5) {
                                    Text("Judges Scores")
                                        .bold()
                                        .underline()
                                    Text(judgesScores.joined(separator: " | "))
                                        .fontWeight(.semibold)
                                }
                                .dynamicTypeSize(.xSmall ... .xxxLarge)
                                .font(.title2)
                            }
                        } else if name != nil, dd == nil {
                                BackgroundBubble() {
                                    Text("Not possible on " + height.rawValue)
                                        .scaledToFit()
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                                }
                                .frame(minWidth: screenWidth * 0.5, maxWidth: screenWidth * 0.95, minHeight: screenHeight * 0.09, maxHeight: screenHeight * 0.11)
                            
                        }
                    }
                    .onAppear {
                        tableData = getDiveTableData()
                    }
                }
                .frame(width: screenWidth * 0.95)
            }
        }
    }
    
    struct DiveHeightSelectView: View {
        @Binding var height: DiveHeight
        
        private let cornerRadius: CGFloat = 30
        private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Custom.darkGray)
                    .shadow(radius: 10)
                HStack(spacing: 0) {
                    ForEach(DiveHeight.allCases, id: \.self) { h in
                        ZStack {
                            // Weird padding stuff to have end options rounded on the outside edge
                            // only when selected
                            // https://stackoverflow.com/a/72435691/22068672
                            Rectangle()
                                .fill(height == h ? selectedGray : .clear)
                                .padding(.trailing, h == DiveHeight.allCases.first
                                         ? cornerRadius
                                         : 0)
                                .padding(.leading, h == DiveHeight.allCases.last
                                         ? cornerRadius
                                         : 0)
                                .cornerRadius(h == DiveHeight.allCases.first ||
                                              h == DiveHeight.allCases.last
                                              ? cornerRadius
                                              : 0)
                                .padding(.trailing, h == DiveHeight.allCases.first
                                         ? -cornerRadius
                                         : 0)
                                .padding(.leading, h == DiveHeight.allCases.last
                                         ? -cornerRadius
                                         : 0)
                            Text(h.rawValue)
                        }
                        .dynamicTypeSize(.xSmall ... .xxxLarge)
                        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .onTapGesture {
                            height = h
                        }
                        if h != DiveHeight.allCases.last {
                            Divider()
                        }
                    }
                }
            }
            .frame(height: 50)
            .padding([.leading, .trailing])
        }
    }
}
