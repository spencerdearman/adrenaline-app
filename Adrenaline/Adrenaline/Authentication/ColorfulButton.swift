//
//  ColorfulButton.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/28/23.
//

import SwiftUI

struct ColorfulButton: View {
    var title = ""
    @State var tap = false
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    
    var body: some View {
        Text(completedLongPress ? "Loading..." : title)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(
                ZStack {
                    angularGradient
                    LinearGradient(gradient: Gradient(colors: [Color(.systemBackground).opacity(1), Color(.systemBackground).opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                        .cornerRadius(20)
                        .blendMode(.softLight)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.linearGradient(colors: [.white.opacity(0.8), .black.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .blendMode(.overlay)
            )
            .frame(height: 50)
            .accentColor(.primary.opacity(0.7))
            .background(angularGradient)
            .scaleEffect(isDetectingLongPress ? 0.8 : 1)
    }
    
    var angularGradient: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.clear)
            .padding(6)
            .blur(radius: 20)
    }
}

struct ColorfulButton_Previews: PreviewProvider {
    static var previews: some View {
        ColorfulButton()
    }
}
