//
//  ExtraSplashView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 6/27/23.
//

import SwiftUI

// Transition starts as idle, moves to bottom of screen, then away to top
enum MoveStage: Int, CaseIterable {
    case idle = 0
    case bottom = 1
    case top = 2
}

struct MovingSplashView: View {
    @Environment(\.colorScheme) var currentMode
    @State var moveStage: MoveStage = .idle
    @State var sphereMoving: [Bool] = [false, false, false, false]
    @Namespace var namespace
    
    private let shadowRadius: CGFloat = 15
    
    let startDelay: CGFloat
    let moveSeparation: CGFloat
    let delayToTop: CGFloat
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    private var imgBgColor: Color {
        currentMode == .light
        ? Color(red: 80 / 255, green: 171 / 255, blue: 234 / 255)
        : Color(red: 65 / 255, green: 142 / 255, blue: 195 / 255)
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ZStack {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midX = width / 2
                    let midY = height / 2
                    let imgSize = width * 0.3
                    let imgBig = width * 0.5
                    let xxxsmall = width * 0.5
                    let xxsmall = width * 0.7
                    let xsmall = width * 0.9
                    let small = width * 0.8
                    let med = width * 1.1
                    let large = width * 1.4
                    let bottomPos = height * 0.8
                    let largeCircle = Circle()
                        .fill(Custom.darkBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(5)
                        .matchedGeometryEffect(id: "sphere1", in: namespace)
                    let medCircle = Circle()
                        .fill(Custom.coolBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(6)
                        .matchedGeometryEffect(id: "sphere2", in: namespace)
                    let smallCircle = Circle()
                        .fill(Custom.medBlue) // Circle color
                        .shadow(radius: shadowRadius)
                        .zIndex(7)
                        .matchedGeometryEffect(id: "sphere3", in: namespace)
                    let image = Image("diverImage")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(currentMode == .light ? .black : .white)
                        .background(imgBgColor)
                        .clipShape(Circle())
                        .shadow(radius: shadowRadius)
                        .zIndex(8)
                        .matchedGeometryEffect(id: "icon", in: namespace)
                    let now = DispatchTime.now()
                    
                    if moveStage == .top {
                        bgColor.ignoresSafeArea()
                            .opacity(0.0)
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 3, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: large, shadowRadius: shadowRadius)
                        { largeCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: now + moveSeparation * 3) {
                                    withAnimation {
                                        sphereMoving[3] = true
                                    }
                                }
                            }
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 2, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: med, shadowRadius: shadowRadius)
                        { medCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: now + moveSeparation * 2) {
                                    withAnimation {
                                        sphereMoving[2] = true
                                    }
                                }
                            }
                        SphereView(sphereMoving: $sphereMoving, sphereIdx: 1, namespace: namespace,
                                   startX: midX, startY: bottomPos, endY: -height * 1,
                                   startSize: small, shadowRadius: shadowRadius)
                        { smallCircle }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: now + moveSeparation * 1) {
                                    withAnimation {
                                        sphereMoving[1] = true
                                    }
                                }
                            }
                        image
                            .position(x: midX, y: sphereMoving[0] ? -height * 1 : bottomPos)
                            .frame(width: imgBig, height: imgBig)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: now) {
                                    withAnimation {
                                        sphereMoving[0] = true
                                    }
                                }
                            }
                    } else if moveStage == .bottom {
                        bgColor.ignoresSafeArea()
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        largeCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: large, height: large)
                        medCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: med, height: med)
                        smallCircle
                            .position(x: midX, y: bottomPos) // Center the circle
                            .frame(width: small, height: small)
                        
                        image
                            .position(x: midX, y: bottomPos)
                            .frame(width: imgBig, height: imgBig)
                    } else if moveStage == .idle {
                        bgColor.ignoresSafeArea()
                            .matchedGeometryEffect(id: "bg", in: namespace)
                        
                        largeCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xsmall, height: xsmall)
                        medCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxsmall, height: xxsmall)
                        smallCircle
                            .position(x: midX, y: midY) // Center the circle
                            .frame(width: xxxsmall, height: xxxsmall)
                        
                        image
                            .position(x: midX, y: midY)
                            .frame(width: imgSize, height: imgSize)
                    }
                }
            }
        }
        .zIndex(100)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                withAnimation {
                    moveStage = .bottom
                }
            }
        }
        .onChange(of: moveStage) { newValue in
            if newValue != .top {
                sphereMoving = [false, false, false, false]
            }
            if moveStage == .bottom {
                DispatchQueue.main.asyncAfter(deadline: .now() + delayToTop) {
                    withAnimation {
                        moveStage = .top
                    }
                }
            }
        }
    }
}

struct SphereView<T: View>: View {
    @Binding var sphereMoving: [Bool]
    let sphereIdx: Int
    let namespace: Namespace.ID
    let startX: CGFloat
    var endX: CGFloat? = nil
    let startY: CGFloat
    var endY: CGFloat? = nil
    let startSize: CGFloat
    var endSize: CGFloat? = nil
    let shadowRadius: CGFloat
    var sphere: () -> T
    
    var body: some View {
        if sphereMoving[sphereIdx] {
            sphere()
                .position(x: endX ?? startX, y: endY ?? startY)
                .frame(width: endSize ?? startSize, height: endSize ?? startSize)
        } else {
            sphere()
                .position(x: startX, y: startY)
                .frame(width: startSize, height: startSize)
        }
    }
}
