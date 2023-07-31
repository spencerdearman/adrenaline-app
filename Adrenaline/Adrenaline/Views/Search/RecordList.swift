//
//  RecordList.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct RecordList: View {
    @Environment(\.colorScheme) var currentMode
    @State var loginSuccessful: Bool = false
    @Binding var records: DiverProfileRecords
    @Binding var adrenalineRecords: [String: User?]
    @Binding var resultSelected: Bool
    @Binding var fullScreenResults: Bool
    @Binding var selectionType: DiveMeetsAdrenaline
    
    // Style adjustments for elements of list
    private let cornerRadius: CGFloat = 30
    private let rowSpacing: CGFloat = 8
    private let textColor: Color = Color.primary
    @ScaledMetric private var viewPadding: CGFloat = 58
    
    private var rowColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    private var customGray: Color {
        let gray = currentMode == .light ? 0.95 : 0.1
        return Color(red: gray, green: gray, blue: gray)
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
            // Background color for View
            Custom.specialGray
            if selectionType == .diveMeets {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        Text("Results")
                            .font(.title).fontWeight(.semibold)
                        Spacer()
                        Spacer()
                        ForEach(getSortedRecords(records), id: \.1) { record in
                            let (key, value) = record
                            NavigationLink(destination: ProfileView(profileLink: value)) {
                                HStack {
                                    Text(key)
                                        .foregroundColor(textColor)
                                        .font(.title3)
                                        .padding()
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                        .padding()
                                }
                                .background(Custom.darkGray)
                                .cornerRadius(cornerRadius)
                                .onDisappear {
                                    resultSelected = true
                                }
                                .onAppear{
                                    resultSelected = false
                                }
                            }
                            .shadow(radius: 5)
                            .padding([.leading, .trailing])
                        }
                    }
                    .padding()
                }
                .padding(.bottom, viewPadding)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: rowSpacing) {
                        Text("Results")
                            .font(.title).fontWeight(.semibold)
                        Spacer()
                        Spacer()
                        ForEach(Array(adrenalineRecords), id: \.key) { record in // Convert dictionary to array with 'Array(adrenalineRecords)'
                            if let value = record.value { // Unwrap the optional User value
                                NavigationLink(destination: AdrenalineProfileView(showBackButton: true, user: Binding(get: { value }, set: { newValue in }), loginSuccessful: $loginSuccessful)) {
                                    HStack {
                                        Text(record.key) // 'record.key' is the String key
                                            .foregroundColor(textColor)
                                            .font(.title3)
                                            .padding()
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.gray)
                                            .padding()
                                    }
                                    .background(Custom.darkGray)
                                    .cornerRadius(cornerRadius)
                                    .onDisappear {
                                        resultSelected = true
                                    }
                                    .onAppear {
                                        resultSelected = false
                                    }
                                }
                                .shadow(radius: 5)
                                .padding([.leading, .trailing])
                            }
                        }
                    }
                    .padding()
                }
                .padding(.bottom, viewPadding)
            }
        }
    }
}
