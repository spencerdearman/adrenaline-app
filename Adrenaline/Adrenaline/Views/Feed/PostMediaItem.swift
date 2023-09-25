//
//  PostMediaItem.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/24/23.
//

import SwiftUI
import AVKit

enum PostMedia {
    case video(VideoPlayer<EmptyView>)
    case image(Image)
}

struct PostMediaItem: Identifiable {
    var id: String = UUID().uuidString
    
    var data: PostMedia
    var view: any View {
        if case let .video(v) = self.data {
            v
        } else if case let .image(i) = self.data {
            i
        } else {
            EmptyView()
        }
    }
    
    init(data: PostMedia) {
        self.data = data
    }
}
