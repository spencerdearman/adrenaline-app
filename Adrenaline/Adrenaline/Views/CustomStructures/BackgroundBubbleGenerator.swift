//
//  BackgroundBubbleGenerator.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct BackgroundBubble<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    var color: Color = Custom.darkGray
    var cornerRadius: CGFloat = 40
    var shadow: CGFloat = 10
    var vPadding: CGFloat = 14
    var hPadding: CGFloat = 14
    var onTapGesture: () -> Void = {}
    var content: () -> Content
    var width: CGFloat {
        contentSize.width + hPadding
    }
    var height: CGFloat {
        contentSize.height + vPadding
    }
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(cornerRadius)
                .shadow(radius: shadow)
                .frame(width: width, height: height)
                .onTapGesture(perform: onTapGesture)
            content()
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                contentSize = geometry.size
                            }
                            .onChange(of: dynamicTypeSize) { // Observe changes to the dynamic type size
                                contentSize = geometry.size
                            }
                    }
                }
        }
    }
}
