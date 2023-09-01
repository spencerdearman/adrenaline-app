//
//  ImprovedPicker.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/4/23.
//  From https://www.mbishop.name/2019/11/odd-behaviors-in-the-swiftui-picker-view/
//

import SwiftUI

/**
 iOS Picker class with the update bug which can cause the SwiftUI picker to reset.
 */
struct NoStickPicker: UIViewRepresentable {
    
    class Coordinator : NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        @Binding var selection: Int
        
        var initialSelection: Int?
        var viewForRow: (Int) -> UIView
        var rowCount: Int
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            rowCount
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int,
                        forComponent component: Int, reusing view: UIView?) -> UIView {
            viewForRow(row)
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                        inComponent component: Int) {
            self.selection = row
        }
        
        init(selection: Binding<Int>, viewForRow: @escaping (Int) -> UIView, rowCount: Int) {
            self.viewForRow = viewForRow
            self._selection = selection
            self.rowCount = rowCount
        }
    }
    
    @Binding var selection: Int
    
    var rowCount: Int
    let viewForRow: (Int) -> UIView
    
    func makeCoordinator() -> NoStickPicker.Coordinator {
        return Coordinator(selection: $selection, viewForRow: viewForRow, rowCount: rowCount)
    }
    
    func makeUIView(context: UIViewRepresentableContext<NoStickPicker>) -> UIPickerView {
        let view = UIPickerView(frame: .zero)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.init(20), for: .vertical)
        view.delegate = context.coordinator
        view.dataSource = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UIPickerView, context: UIViewRepresentableContext<NoStickPicker>) {
        
        context.coordinator.viewForRow = self.viewForRow
        context.coordinator.rowCount = rowCount
        
        if context.coordinator.initialSelection != selection {
            uiView.selectRow(selection, inComponent: 0, animated: true)
            context.coordinator.initialSelection = selection
        }
    }
}
