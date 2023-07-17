//
//  ToolsMenu.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/1/23.
//

import SwiftUI

enum JudgeScoreField: Int, Hashable, CaseIterable {
    case dive
    case score
}

struct ToolsMenu: View {
    @FocusState var focusedField: JudgeScoreField?
    @ScaledMetric private var maxHeightOffsetScaled: CGFloat = 57
    
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    
    private var maxHeightOffset: CGFloat {
        min(maxHeightOffsetScaled, 90)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ToolsColorfulView()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }
                VStack {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Custom.grayThinMaterial)
                            .mask(RoundedRectangle(cornerRadius: 40))
                            .frame(width: 120, height: 40)
                            .shadow(radius: 6)
                        Text("Tools")
                            .font(.title2).bold()
                    }
                    Spacer()
                    VStack {
                        NavigationLink(destination: MeetScoreCalculator()) {
                            ZStack {
                                Rectangle()
                                    .foregroundColor(Custom.grayThinMaterial)
                                    .mask(RoundedRectangle(cornerRadius: 40))
                                    .frame(width: screenWidth * 0.9, height: screenHeight * 0.1)
                                    .shadow(radius: 10)
                                
                                Text("Meet Score Calculator")
                                    .foregroundColor(.primary)
                                    .font(.title2)
                                    .bold()
                                    .padding()
                            }
                        }
                        JudgeScoreCalculator(focusedField: $focusedField)
                            .frame(height: screenHeight * 0.5)
                    }
                    .offset(y: -screenHeight * 0.13)
                }
                .padding(.bottom, maxHeightOffset)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ToolsColorfulView: View {
    @Environment(\.colorScheme) var currentMode
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    private var bgColor: Color {
        currentMode == .light ? Color.white : Color.black
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            Group {
                Wave(graphWidth: 1.3, amplitude: 0.05)
                    .foregroundColor(Custom.lightBlue)
                Wave(graphWidth: 0.8, amplitude: -0.04)
                    .foregroundColor(Custom.medBlue)
                    .offset(y: screenHeight * 0.06)
                Wave(graphWidth: 1.1, amplitude: 0.06)
                    .foregroundColor(Custom.coolBlue)
                    .offset(y: screenHeight * 0.18)
                Wave(graphWidth: 1.3, amplitude: -0.08)
                    .foregroundColor(Custom.darkBlue)
                    .offset(y: screenHeight * 0.22)
            }
            .offset(y: screenHeight * 0.1)
        }
    }
}

struct Wave: Shape {
    let graphWidth: CGFloat
    let amplitude: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        let origin = CGPoint(x: 0, y: height * 0.50)
        
        var path = Path()
        path.move(to: origin)
        
        var endY: CGFloat = 0.0
        let step = 5.0
        for angle in stride(from: step, through: Double(width) * (step * step), by: step) {
            let x = origin.x + CGFloat(angle/360.0) * width * graphWidth
            let y = origin.y - CGFloat(sin(angle/180.0 * Double.pi)) * height * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            endY = y
        }
        path.addLine(to: CGPoint(x: width, y: endY))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: origin.y))
        
        return path
    }
}
