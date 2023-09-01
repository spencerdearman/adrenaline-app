//
//  HideTabBarGesture.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/21/23.
//

import SwiftUI

struct HideTabBarGesture: ViewModifier {
    @Binding var tabBarState: Visibility
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture().onChanged({ gesture in
                if gesture.translation.height < 0 { tabBarState = .hidden }
                else if gesture.translation.height > 0 { tabBarState = .visible }
            }))
            .toolbar(tabBarState, for: .tabBar)
            .animation(.easeInOut(duration: 0.3), value: tabBarState)
    }
}
