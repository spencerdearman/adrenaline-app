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
class FeedItem: Hashable, Identifiable {
    var id: String = UUID().uuidString
    var isExpanded: Bool = false
    var collapsedView: any View = EmptyView()
    var expandedView: any View = EmptyView()
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        return lhs.id == rhs.id
    }
}

enum Media {
    case video(VideoPlayer<EmptyView>)
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
