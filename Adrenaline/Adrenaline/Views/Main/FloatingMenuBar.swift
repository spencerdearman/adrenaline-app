//
//  FloatingMenuBar.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 2/28/23.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case house
    case wrench
    case person
    case magnifyingglass
}

private func IntFromTab(_ t: Tab) -> Int {
    var i: Int = 0
    for e in Tab.allCases {
        if e == t {
            return i
        }
        i += 1
    }
    // This should not be possible to reach since t is a Tab and we are iterating over all Tabs,
    // so it will always reach the inner if statement and return
    return -1
}

// Haptic feedback
func simpleSuccess() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}

struct FloatingMenuBar: View {
    @Environment(\.colorScheme) var currentMode
    
    @Binding var selectedTab: Tab
    @State var hideTabBar: Bool = false
    @State var visibleTabs: [Tab] = Tab.allCases
    @State var relaxImage: Bool = false
    private let cornerRadius: CGFloat = 50
    @ScaledMetric private var frameHeightScaled: CGFloat = 60
    private let menuBarHideDelay: CGFloat = 0.75
    private let menuBarShowDelay: CGFloat = 0.55

    private var frameHeight: CGFloat {
        min(frameHeightScaled, 100)
    }
    
    // Add custom multipliers for selected tabs here, defaults to 1.25
    private let sizeMults: [String: Double] = [
        "magnifyingglass": 1.5,
        "house.circle": 1.75,
        "gearshape.circle": 1.6,
        "person.circle": 1.6,
        "magnifyingglass.circle": 1.5,
        "wrench.and.screwdriver": 1.75,
        "wrench.and.screwdriver.circle": 1.75,
    ]
    
    // Computes the image path to use when an image is selected
    private var fillImage: String {
        selectedTab.rawValue == "magnifyingglass"
        ? selectedTab.rawValue + ".circle.fill"
        : (selectedTab.rawValue == "wrench"
           ? selectedTab.rawValue + ".and.screwdriver.fill"
           : selectedTab.rawValue + ".fill")
    }
    
    // Computes the image path for the selected image when it is relaxed
    private var selectedImageInverse: String {
        selectedTab.rawValue == "wrench"
        ? selectedTab.rawValue + ".and.screwdriver.circle"
        : selectedTab.rawValue + ".circle"
    }
    
    // Computes the image path for the selected image when the state is relaxed vs not
    private var selectedTabImage: String {
        relaxImage ? selectedImageInverse : fillImage
    }
    
    // Computes the color to use for the selected image
    private var selectedColor: Color {
        currentMode == .light ? .white : .black
    }
    
    // Color for selected image icons
    private let deselectedColor: Color = .gray
    
    // Computes the color for the moving selection bubble
    private var selectedBubbleColor: Color {
        currentMode == .light ? .black : .white
    }
    
    // Computes the color of the icon based on the selected color and relaxed vs not
    private var selectedTabColor: Color {
        if relaxImage {
            return selectedBubbleColor == .black ? .black : .white
        } else {
            return selectedBubbleColor == .black ? .white : .black
        }
    }
    
    // Computes the opacity of the icon when relaxed vs not
    private var selectedTabOpacity: CGFloat {
        relaxImage ? 0.5 : 1
    }
    
    // Computes the x offset of the icon based on the width of tabs
    private func selectedXOffset(from tabWidth: CGFloat) -> CGFloat {
        let tabInt: CGFloat = CGFloat(IntFromTab(selectedTab))
        let casesCount: Int = Tab.allCases.count
        
        // Sets midpoint to middle icon index, chooses left of middle if even num of
        // choices
        var menuBarMidpoint: CGFloat {
            casesCount.isMultiple(of: 2)
            ? (CGFloat(casesCount) - 1) / 2
            : floor(CGFloat(casesCount) / 2)
        }
        
        // Offset that appears to be necessary when there are more than three tabs
        let addXOff: CGFloat = casesCount > 3 ? 2 : 0
        
        return tabWidth * (tabInt - menuBarMidpoint) + addXOff
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                // Width of menu bar
                let geoWidth: CGFloat =
                visibleTabs.count > 1
                ? geometry.size.width
                : frameHeight
                
                // Width of bubble for one tab
                let tabWidth: CGFloat =
                visibleTabs.count > 1
                ? ((geoWidth - 0) /
                   CGFloat(Tab.allCases.count))
                : geoWidth
                
                // x offset from center of tab bar to selected tab
                let xOffset: CGFloat =
                visibleTabs.count > 1
                ? selectedXOffset(from: tabWidth)
                : 0
                
                ZStack {
                    // Clear background of menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .frame(width: geoWidth, height: frameHeight)
                        .animation(.spring(), value: visibleTabs)
                    
                    // Moving bubble on menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(relaxImage ? .clear : selectedBubbleColor)
                        .frame(width: tabWidth, height: frameHeight)
                        .offset(x: xOffset)
                        .animation(.spring(), value: visibleTabs)
                        .animation(.spring(), value: selectedTab)
                        .animation(.easeOut, value: relaxImage)
                    
                    // Line of buttons for each tab
                    HStack(spacing: 0) {
                        ForEach(visibleTabs, id: \.rawValue) { tab in
                            Spacer()
                            Group {
                                if tab == .wrench && relaxImage {
                                    Image(selectedTab == tab ? selectedTabImage : (tab == .wrench ? tab.rawValue + ".and.screwdriver.circle" : tab.rawValue))
                                } else {
                                    Image(systemName: selectedTab == tab ? selectedTabImage : (tab == .wrench ? tab.rawValue + ".and.screwdriver" : tab.rawValue))
                                }
                            }
                            .scaleEffect(tab == selectedTab
                                         ? sizeMults[selectedTabImage] ?? 1.25
                                         : 1.0)
                            .foregroundColor(selectedTab == tab
                                             ? selectedTabColor
                                             : deselectedColor)
                            .opacity(selectedTab == tab ? selectedTabOpacity : 1.0)
                            .font(.title2)
                            .dynamicTypeSize(.medium ... .xxxLarge)
                            // Adds tab change and visible tabs change on button press
                            .onTapGesture() {
                                if !hideTabBar {
                                        simpleSuccess()
                                        selectedTab = tab
                                        visibleTabs = [tab]
                                        hideTabBar = true
                                        
                                        DispatchQueue.main.asyncAfter(
                                            deadline: (DispatchTime.now() +
                                                       menuBarHideDelay)) {
                                                           relaxImage = true
                                                       }
                                } else {
                                        simpleSuccess()
                                        relaxImage = false
                                        
                                        DispatchQueue.main.asyncAfter(
                                            deadline: (DispatchTime.now() +
                                                       menuBarShowDelay)) {
                                                           visibleTabs = Tab.allCases
                                                           hideTabBar = false
                                                       }
                                    }
                            }
                            .animation(.spring(), value: visibleTabs)
                            Spacer()
                        }
                    }
                }
            }
            .frame(height: frameHeight)
            .cornerRadius(cornerRadius)
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                visibleTabs = [selectedTab]
                hideTabBar = true
                DispatchQueue.main.asyncAfter(deadline: .now() + menuBarHideDelay) {
                    relaxImage = true
                }
            }
        }
    }
}

