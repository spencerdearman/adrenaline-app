//
//  HideTabBarScrollView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/21/23.
//

import SwiftUI

struct HideTabBarScrollView<Content: View>: View {
    @Binding var tabBarState: Visibility
    var content: Content
    
    init(tabBarState: Binding<Visibility>, content: @escaping () -> Content) {
        self._tabBarState = tabBarState
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            content
        }
        .modifier(HideTabBarGesture(tabBarState: $tabBarState))
    }
}
