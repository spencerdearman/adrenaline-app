//
//  MeetScoreCalculator.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/1/23.
//

import SwiftUI

enum MeetType: String, CaseIterable {
    case one = "1M"
    case three = "3M"
    case platform = "Platform"
}

enum DiveHeight: String, CaseIterable {
    case one = "1M"
    case three = "3M"
    case five = "5M"
    case seven = "7.5M"
    case ten = "10M"
}

// If providing dives list, also need to provide numDives so it doesn't clear dives list on appear
struct MeetScoreCalculator: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @State var tableData: [String: DiveData]?
    @State var numDives: Int = 2
    @State var meetType: MeetType = .one
    @State var dives: [String] = []
    @State var diveNetScores: [Double] = []
    @State var diveTotalScores: [Double] = []
    @FocusState var focusedField: Bool?
    
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 57
    @ScaledMetric private var navButtonHeightScaled: CGFloat = 35
    
    private var navButtonHeight: CGFloat {
        min(navButtonHeightScaled, 55)
    }
    
    private var navButtonWidth: CGFloat {
        navButtonHeight * 1.75
    }
    
    private let cornerRadius: CGFloat = 30
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private func clearDivesList() {
        dives = []
        diveNetScores = []
        diveTotalScores = []
        for _ in 0..<numDives {
            dives.append("")
            diveNetScores.append(0.0)
            diveTotalScores.append(0.0)
        }
        
        focusedField = nil
    }
    
    private func setDivesList() {
        diveNetScores = []
        diveTotalScores = []
        for _ in 0..<numDives {
            if dives.count < numDives {
                dives.append("")
            }
            diveNetScores.append(0.0)
            diveTotalScores.append(0.0)
        }
    }
    
    private func refreshDives() {
        for idx in 0..<numDives {
            if idx >= dives.count {
                dives.append("")
            }
            if idx < diveNetScores.count {
                diveNetScores[idx] += 0.0
            } else {
                diveNetScores.append(0.0)
            }
            if idx < diveTotalScores.count {
                diveTotalScores[idx] = diveNetScores[idx] * 1.0
            } else {
                diveTotalScores.append(0.0)
            }
        }
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack {
//                HStack {
//                    Spacer()
//                    Button("Clear") {
//                        clearDivesList()
//                    }
//                    .buttonStyle(.bordered)
//                    .cornerRadius(cornerRadius)
//                    .padding([.trailing])
//                }
                
                Text("Meet Score Calculator")
                    .font(.title)
                    .bold()
                
                CalculatorTopView(tableData: $tableData, numDives: $numDives, meetType: $meetType,
                                  dives: $dives)
                .onChange(of: numDives) {
                    refreshDives()
                }
                .onChange(of: meetType) {
                    refreshDives()
                }
                .onAppear {
                    if dives.count > 0 {
                        numDives = dives.count
                    }
                    setDivesList()
                    if dives.count > 0 {
                        refreshDives()
                    }
                }
                
                let total = diveTotalScores.reduce(into: 0.0, { $0 += $1 })
                if total > 0.0 {
                    HStack(spacing: 0) {
                        Text("Meet Total: ")
                            .bold()
                        Text(String(format: "%.2f", total))
                            .fontWeight(.semibold)
                        
                    }
                    .font(.title2)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: cornerRadius).fill(.thinMaterial))
                }
                
                Divider()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(0..<numDives, id: \.self) { i in
                            CalculatorRowView(tableData: $tableData, dives: $dives, meetType: $meetType,
                                              diveNetScores: $diveNetScores,
                                              diveTotalScores: $diveTotalScores,
                                              focusedField: $focusedField, idx: i)
                            .padding(.top, i == 0 ? 10 : 0)
                            .padding(.bottom, i == numDives - 1 ? 10 : 0)
                        }
                    }
                }
                .background(.clear)
            }
            .padding(.bottom, maxHeightOffset)
        }
        .onAppear {
            tableData = getDiveTableData()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .foregroundColor(Custom.grayThinMaterial)
                            .shadow(radius: 4)
                            .frame(width: navButtonWidth, height: navButtonHeight)
                        Text("Clear")
                            .foregroundColor(.primary)
//                        .frame(width: navButtonHeight * 1.75, height: navButtonHeight)
                    }
                    .onTapGesture {
                        clearDivesList()
                    }
            }
        }
    }
}

struct CalculatorTopView: View {
    @Binding var tableData: [String: DiveData]?
    @Binding var numDives: Int
    @Binding var meetType: MeetType
    @Binding var dives: [String]
    
    private let cornerRadius: CGFloat = 30
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
            HStack(spacing: 0) {
                ForEach(MeetType.allCases, id: \.self) { m in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge only
                        // when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(meetType == m ? selectedGray : .clear)
                            .padding(.trailing, m == MeetType.allCases.first ? cornerRadius : 0)
                            .padding(.leading, m == MeetType.allCases.last ? cornerRadius : 0)
                            .cornerRadius(m == MeetType.allCases.first || m == MeetType.allCases.last
                                          ? cornerRadius : 0)
                            .padding(.trailing, m == MeetType.allCases.first ? -cornerRadius : 0)
                            .padding(.leading, m == MeetType.allCases.last ? -cornerRadius : 0)
                        Text(m.rawValue)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        meetType = m
                    }
                    if m != MeetType.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 50)
        .padding([.leading, .trailing])
        
        HStack {
            Text("Number of Dives:")
            Picker("", selection: $numDives) {
                ForEach(0...11, id: \.self) { i in
                    Text(String(i))
                        .tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 80)
        }
        .padding([.leading, .trailing])
    }
}

struct CalculatorRowView: View {
    @Environment(\.colorScheme) var currentMode
    @State var diveHeight: DiveHeight = .five
    @State var judgeScores: [Int] = [10, 10, 10]
    @State var scoreValues: [Double] = Array(stride(from: 0.0, to: 10.5, by: 0.5))
    @Binding var tableData: [String: DiveData]?
    @Binding var dives: [String]
    @Binding var meetType: MeetType
    @Binding var diveNetScores: [Double]
    @Binding var diveTotalScores: [Double]
    fileprivate var focusedField: FocusState<Bool?>.Binding
    
    let idx: Int
    
    @ScaledMetric var wheelPickerSelectedSpacing: CGFloat = 40
    
    private var bubbleColor: Color {
        currentMode == .light ? .white : .black
    }
    
    private var meetTypeDouble: Double? {
        if meetType == .one {
            return 1.0
        } else if meetType == .three {
            return 3.0
        }
        
        return nil
    }
    
    private var diveName: String {
        if idx < dives.count {
            return getDiveName(data: tableData ?? [:],
                               forKey: $dives[idx].wrappedValue) ?? ""
        }
        
        return ""
    }
    
    private var dd: Double {
        if idx < dives.count {
            return getDiveDD(data: tableData ?? [:], forKey: $dives[idx].wrappedValue,
                             height: meetTypeDouble == nil
                             ? Double(String(diveHeight.rawValue.dropLast())) ?? 0.0
                             : meetTypeDouble!) ?? 0.0
        }
        
        return 0.0
    }
    
    private func updateNetAndTotalScores() {
        if idx < diveNetScores.count {
            diveNetScores[idx] = judgeScores.reduce(into: 0.0, { $0 += scoreValues[$1] })
        }
        if idx < diveTotalScores.count {
            diveTotalScores[idx] = diveNetScores[idx] * dd
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Custom.darkGray)
                .shadow(radius: 5)
            
            VStack {
                HStack {
                    if idx < dives.count {
                        TextField("Number", text: $dives[idx])
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                            .focused(focusedField, equals: true)
                            .frame(width: 80)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 5) {
                            Text("Name:")
                                .fontWeight(.semibold)
                            
                            // Only shows name if there is an associated DD, otherwise show N/A
                            dd == 0.0 ? Text("N/A") : Text(diveName)
                        }
                        
                        if meetType == .platform {
                            HStack(spacing: 0) {
                                Text("Height: ")
                                    .fontWeight(.semibold)
                                PlatformHeightSelectView(diveHeight: $diveHeight)
                            }
                        }
                        
                        
                        HStack(spacing: 0) {
                            Text("DD: ")
                                .fontWeight(.semibold)
                            // Shows N/A if there is not an associated dd with that height
                            Text(dd == 0.0 ? "N/A" : String(dd))
                        }
                    }
                    
                    Spacer()
                }
                ForEach(0..<3) { i in
                    HStack {
                        Text("Judge \(i+1):")
                            .fontWeight(.semibold)
                        SwiftUIWheelPicker($judgeScores[i], items: scoreValues) { value in
                            GeometryReader { g in
                                Text(String(format: "%.1f", value))
                                    .frame(width: g.size.width, height: g.size.height,
                                           alignment: .center)
                            }
                        }
                        .scrollAlpha(0.1)
                        .centerView(AnyView(
                            HStack(alignment: .center, spacing: 0) {
                                Divider()
                                    .frame(width: 1)
                                    .background(Color.gray)
                                    .opacity(0.4)
                                Spacer()
                                Divider()
                                    .frame(width: 1)
                                    .background(Color.gray)
                                    .opacity(0.4)
                            }
                        ), width: .Fixed(wheelPickerSelectedSpacing))
                        .onChange(of: judgeScores[i]) {
                            updateNetAndTotalScores()
                        }
                        .onChange(of: dives) {
                            updateNetAndTotalScores()
                        }
                        .onChange(of: meetType) {
                            updateNetAndTotalScores()
                        }
                        .onChange(of: diveNetScores) {
                            updateNetAndTotalScores()
                        }
                        .onAppear {
                            updateNetAndTotalScores()
                        }
                    }
                }
                
                if idx < diveNetScores.count && diveNetScores[idx] != 0.0 {
                    HStack(spacing: 0) {
                        Spacer()
                        Text("Net Score: ")
                            .fontWeight(.semibold)
                        Text(String(diveNetScores[idx]))
                    }
                    .padding(.top)
                    HStack(spacing: 0) {
                        Spacer()
                        Text("Total Score: ")
                            .fontWeight(.semibold)
                        Text(String(format: "%.2f", diveTotalScores[idx]))
                    }
                }
            }
            .padding()
        }
        .padding([.leading, .trailing])
    }
}

struct PlatformHeightSelectView: View {
    @Binding var diveHeight: DiveHeight
    
    private let cornerRadius: CGFloat = 30
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    private let diveHeights: [DiveHeight] = [.five, .seven, .ten]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
            HStack(spacing: 0) {
                ForEach(diveHeights, id: \.self) { h in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge only
                        // when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(diveHeight == h ? selectedGray : .clear)
                            .padding(.trailing, h == diveHeights.first ? cornerRadius : 0)
                            .padding(.leading, h == diveHeights.last ? cornerRadius : 0)
                            .cornerRadius(h == diveHeights.first || h == diveHeights.last
                                          ? cornerRadius : 0)
                            .padding(.trailing, h == diveHeights.first ? -cornerRadius : 0)
                            .padding(.leading, h == diveHeights.last ? -cornerRadius : 0)
                        Text(h.rawValue)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        diveHeight = h
                    }
                    if h != diveHeights.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 30)
        .padding([.leading, .top, .bottom], 5)
    }
}
