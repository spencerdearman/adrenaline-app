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
    private let tabs: [Tab] = Tab.allCases
    private let cornerRadius: CGFloat = 50
    @ScaledMetric private var frameHeightScaled: CGFloat = 60

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
    
    // Computes the image path for the selected image when the state is relaxed vs not
    private var selectedTabImage: String {
        fillImage
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
        selectedBubbleColor == .black ? .white : .black
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
                let geoWidth: CGFloat = geometry.size.width
                
                // Width of bubble for one tab
                let tabWidth: CGFloat = (geoWidth - 0) / CGFloat(Tab.allCases.count)
                
                // x offset from center of tab bar to selected tab
                let xOffset: CGFloat = selectedXOffset(from: tabWidth)
                
                ZStack {
                    // Clear background of menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .frame(width: geoWidth, height: frameHeight)
                    
                    // Moving bubble on menu bar
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(selectedBubbleColor)
                        .frame(width: tabWidth, height: frameHeight)
                        .offset(x: xOffset)
                        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: selectedTab)
                    
                    // Line of buttons for each tab
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.rawValue) { tab in
                            Spacer()
                            Image(systemName: selectedTab == tab
                                  ? selectedTabImage
                                  : (tab == .wrench
                                     ? tab.rawValue + ".and.screwdriver"
                                     : tab.rawValue))
                            .scaleEffect(tab == selectedTab
                                         ? sizeMults[selectedTabImage] ?? 1.25
                                         : 1.0)
                            .foregroundColor(selectedTab == tab
                                             ? selectedTabColor
                                             : deselectedColor)
                            .font(.title2)
                            .dynamicTypeSize(.medium ... .xxxLarge)
                            // Adds tab change and visible tabs change on button press
                            .onTapGesture() {
                                simpleSuccess()
                                selectedTab = tab
                            }
                            .animation(.spring(), value: selectedTab)
                            Spacer()
                        }
                    }
                }
            }
            .frame(height: frameHeight)
            .cornerRadius(cornerRadius)
            .padding()
        }
    }
}

