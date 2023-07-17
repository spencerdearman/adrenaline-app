//
//  LoginTextFieldClearButton.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/4/23.
// Modified from https://sanzaru84.medium.com/swiftui-how-to-add-a-clear-button-to-a-textfield-9323c48ba61c
//

import SwiftUI

struct LoginTextFieldClearButton: ViewModifier {
    @Binding var text: String
    var fieldType: LoginField
    var focusedField: FocusState<LoginField?>.Binding
    
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
