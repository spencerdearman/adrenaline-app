//
//  FeedModel.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import Combine

struct FeedModel {
    // Tab Bar
    var showTab: Bool = true
    
    // Navigation Bar
    var showNav: Bool = true
    
    // Detail View
    var showDetail: Bool = false
    var selectedItem: String = ""
}

extension Animation {
    static let openCard = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let closeCard = Animation.spring(response: 0.6, dampingFraction: 0.9)
    static let flipCard = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let tabSelection = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

