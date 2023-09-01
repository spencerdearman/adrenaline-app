//
//  SearchButton.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct SearchButton: View {
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        Group {
            ZStack {
                Rectangle()
                    .foregroundColor(.white)
                    .opacity(0.8)
                    .frame(width: screenWidth * 0.08, height: screenWidth * 0.08)
                    .mask(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
                Image(systemName: "magnifyingglass")
                    .scaleEffect(0.9)
                    .opacity(0.6)
                    .frame(width: screenWidth * 0.1, height: screenWidth * 0.1)
                    .mask(RoundedRectangle(cornerRadius: 10))
                    .clipped()
            }
            .opacity(0.9)
            
        }
    }
}

struct SearchButton_Previews: PreviewProvider {
    static var previews: some View {
        SearchButton()
    }
}
