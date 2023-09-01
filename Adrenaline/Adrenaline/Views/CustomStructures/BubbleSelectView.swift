//
//  BubbleSelectView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/30/23.
//

import SwiftUI

struct BubbleSelectView<E: CaseIterable & Hashable & RawRepresentable>: View
where E.RawValue == String, E.AllCases: RandomAccessCollection {
    @Binding var selection: E
    
    
    private let cornerRadius: CGFloat = 15
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
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
                            .foregroundColor(.secondary)
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

