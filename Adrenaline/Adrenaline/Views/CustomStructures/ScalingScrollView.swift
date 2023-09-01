//
//  ScalingScrollView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 5/11/23.
//

import SwiftUI

struct ScalingScrollView<T: RandomAccessCollection, U: View>: View where T.Element: Hashable {
    @Environment(\.colorScheme) var currentMode
    
    private let grayValue: CGFloat = 0.95
    private let grayValueDark: CGFloat = 0.10
    
    private var grayColor: Color {
        currentMode == .light
        ? Color(red: grayValue, green: grayValue, blue: grayValue)
        : Color(red: grayValueDark, green: grayValueDark, blue: grayValueDark)
    }
    
    
    var records: T
    var bgColor: Color? = nil
    var viewHeight: CGFloat = 100
    var rowSpacing: CGFloat = 20
    var shadowRadius: CGFloat? = nil
    var viewGenerator: (T.Element) -> U
    
    @ScaledMetric private var scaledFrameHeight: CGFloat = 100
    private let defaultHeight: CGFloat = 100
    
    var frameHeight: CGFloat {
        viewHeight + (scaledFrameHeight - defaultHeight)
    }
    
    var body: some View {
        GeometryReader { mainView in
            ScrollView(showsIndicators: false) {
                VStack(spacing: rowSpacing) {
                    ForEach(records, id: \.self) { record in
                        GeometryReader { item in
                            viewGenerator(record)
                                .cornerRadius(15)
                                .shadow(radius: shadowRadius ?? 0)
                                .scaleEffect(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                        minY: item.frame(in: .global).minY),
                                             anchor: .bottom)
                                .opacity(scaleValue(mainFrame: mainView.frame(in: .global).minY,
                                                    minY: item.frame(in: .global).minY))
                        }
                        .frame(height: frameHeight)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 25)
            }
            .zIndex(1)
        }
        .background(bgColor == nil ? grayColor : bgColor)
    }
    
    func scaleValue(mainFrame: CGFloat, minY: CGFloat) -> CGFloat {
        withAnimation(.easeOut) {
            let scale = (minY - 25) / mainFrame
            
            if scale > 1 {
                return 1
            } else if scale == 0 {
                return 1e-5
            } else {
                return scale
            }
        }
    }
}
