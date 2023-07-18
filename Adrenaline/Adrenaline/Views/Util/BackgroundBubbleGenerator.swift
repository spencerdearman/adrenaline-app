//
//  BackgroundBubbleGenerator.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct BackgroundBubble<Content: View>: View {
    var content: () -> Content
    var color: Color = Custom.darkGray
    var cornerRadius: CGFloat = 40
    var shadow: CGFloat = 10
    var padding: CGFloat = 14
    var width: CGFloat {
        contentSize.width + padding
    }
    var height: CGFloat {
        contentSize.height + padding
    }
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(cornerRadius)
                .shadow(radius: shadow)
                .frame(width: width, height: height)
            content()
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                contentSize = geometry.size
                            }
                    }
                }
        }
    }
}
