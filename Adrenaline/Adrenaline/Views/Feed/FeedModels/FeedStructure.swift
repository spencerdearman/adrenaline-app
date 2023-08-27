//
//  FeedStructure.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import UIKit
import AVKit


// FeedItems should not be initialized, only used for inheritance
class FeedItem: Identifiable {
    var id: String = UUID().uuidString
    var isExpanded: Bool = false
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
}

enum Media {
    case video(VideoItem)
    case text(String)
}

class SuggestedFeedItem: FeedItem {
    var suggested: String
    
    init(suggested: String, collapsed: @escaping () -> any View,
         expanded: @escaping () -> any View) {
        self.suggested = suggested
        super.init()
    }
}
