//
//  SearchButton.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct ProfileButton: View {
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var imageName: String
    var body: some View {
        Group {
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .opacity(0.6)
                    .frame(width: screenWidth * 0.1, height: screenWidth * 0.1)
                    .mask(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 5)
                Image(imageName)
                    .resizable()
                    .frame(width: screenWidth * 0.065, height: screenWidth * 0.065)
                    .mask(RoundedRectangle(cornerRadius: 10))
                    .clipped()
            }
            
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .inset(by: 0.5)
                .stroke(LinearGradient(gradient: Gradient(colors: [.white, .gray]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1).opacity(0.1))
    }
}

struct ProfileButton_Previews: PreviewProvider {
    static var previews: some View {
        ProfileButton(imageName: "Spencer")
    }
}
