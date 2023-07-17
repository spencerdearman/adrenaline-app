//
//  NavigationViewBackButton.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 7/14/23.
//

import SwiftUI

struct NavigationViewBackButton: View {
    @ScaledMetric private var buttonHeightScaled: CGFloat = 35
    
    private var buttonHeight: CGFloat {
        min(buttonHeightScaled, 55)
    }
    
    private var buttonWidth: CGFloat {
        buttonHeight * 1.7
    }
    
    private var arrowWidth: CGFloat {
        buttonWidth * 0.45
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Custom.grayThinMaterial)
                .shadow(radius: 4)
                .frame(width: buttonWidth, height: buttonHeight)
            Image("longLeftArrow")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.primary)
                .frame(width: arrowWidth)
        }
    }
}
