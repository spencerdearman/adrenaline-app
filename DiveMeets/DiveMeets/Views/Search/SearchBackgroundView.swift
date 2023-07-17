//
//  SearchBackgroundView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 7/11/23.
//

import SwiftUI
import SceneKit


struct SearchColorfulView: View {
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    var colors: [Color] = [Color.white, Custom.lightBlue, Custom.medBlue, Custom.coolBlue, Custom.darkBlue]
    
    var body: some View{
        Group {
            ZStack {
                // CENTER ELLIPSE
                Group {
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2, height: screenHeight/1.4)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4)
                    
                    // FIRST ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.1, height: screenHeight/1.35)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.35) / 2))
                    
                    // SECOND ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.2, height: screenHeight/1.3)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.3) / 2))
                    
                    // THIRD ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.3, height: screenHeight/1.25)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.25) / 2))
                    
                    // FOURTH ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.4, height: screenHeight/1.2)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.2) / 2))
                    
                    // FIFTH ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.5, height: screenHeight/1.15)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.15) / 2))
                    
                    // SIXTH ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.6, height: screenHeight/1.1)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.1) / 2))
                    
                    // SEVENTH ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.7, height: screenHeight/1.05)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1.05) / 2))
                    
                    // EIGHTH ELLIPSE TO LEFT
                    Ellipse()
                        .stroke(LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top), lineWidth: 3)
                        .frame(width: screenWidth * 2.8, height: screenHeight/1)
                    //.rotationEffect(Angle(degrees: 180))
                        .offset(x: screenWidth, y: screenHeight / 4 + ((screenHeight/1.4 - screenHeight/1) / 2))
                }
            }
            .frame(width: screenWidth, height: screenHeight * 0.85)
            .clipped()
        }
        .offset(y: (screenHeight * 0.15) / 2)
        .ignoresSafeArea(.keyboard)
    }
}
