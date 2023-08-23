//
//  FeedBase.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct FeedBase: View {
    @Environment(\.colorScheme) var currentMode
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        ZStack {
            Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                .offset(x: screenWidth * 0.27, y: -screenHeight * 0.05)
                .opacity(0.9)
                .blur(radius: 0.2)
                .scaleEffect(1.1)
            
            VStack {
                // Top Menu Bar
                HStack {
                    // Adrenaline Title
                    Text("Adrenaline")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    Spacer()
                    SearchButton()
                    ProfileButton(imageName: "Spencer")
                }
                .frame(width: screenWidth * 0.87)
                .offset(y: -screenHeight * 0.42)
            }
        }
    }
}

struct FeedBase_Previews: PreviewProvider {
    static var previews: some View {
        FeedBase()
    }
}
