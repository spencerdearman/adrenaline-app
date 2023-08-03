//
//  TextFieldClearButton.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/3/23.
//  Modified from
//  https://sanzaru84.medium.com/swiftui-how-to-add-a-clear-button-to-a-textfield-9323c48ba61c
//

import SwiftUI

// Works with any hashable enum type for focus states
struct TextFieldClearButton<E: Hashable>: ViewModifier {
    @Binding var text: String
    var fieldType: E
    var focusedField: FocusState<E?>.Binding
    
    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            content
            
            if !text.isEmpty && focusedField.wrappedValue == fieldType {
                Button(
                    action: { self.text = "" },
                    label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                )
                .padding(.trailing, 7)
            }
        }
    }
}
