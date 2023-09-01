//
//  TileSwapView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/20/23.
//

import SwiftUI

// Only works with two views that have to be passed in directly
struct TileSwapView<U: View, V: View>: View {
    var topView: U
    var bottomView: V
    var width: CGFloat
    var height: CGFloat
    var swapTime: CGFloat = 0.2
    var offset: CGFloat = 20
    var scaleFactor: CGFloat = 0.9
    
    @State private var zIndices: [Double] = [1, 0]
    @State private var isInTransition: [Bool] = [false, false]
    
    private func getYOffset(index: Int) -> CGFloat {
        if isInTransition[index] {
            return -height + offset
        } else if zIndices[index] == 1 {
            return 0.0
        } else {
            return offset
        }
    }
    
    private func swap(index: Int) {
        isInTransition[index] = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + swapTime) {
            zIndices.reverse()
            isInTransition[index] = false
        }
    }
    
    var body: some View {
        ZStack {
            topView
                .frame(width: zIndices[0] == 1 ? width : width * scaleFactor, height: height)
                .zIndex(zIndices[0])
                .offset(y: getYOffset(index: 0))
                .onSwipeGesture(.up, trigger: .onEnded) {
                    if zIndices[0] == 1 { swap(index: 0) }
                }
                .animation(.spring(), value: isInTransition[0])
                .animation(.spring(), value: zIndices)
            bottomView
                .frame(width: zIndices[1] == 1 ? width : width * scaleFactor, height: height)
                .zIndex(zIndices[1])
                .offset(y: getYOffset(index: 1))
                .onSwipeGesture(.up, trigger: .onEnded) {
                    if zIndices[1] == 1 { swap(index: 1) }
                }
                .animation(.spring(), value: isInTransition[1])
                .animation(.spring(), value: zIndices)
        }
    }
}
