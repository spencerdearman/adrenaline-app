//
//  PostMediaItem.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/24/23.
//

import SwiftUI
import AVKit


enum PostMedia {
    case video(VideoPlayerViewModel)
    case image(Image)
}

struct PostMediaItem: Identifiable {
    var id: String = UUID().uuidString
    var data: PostMedia
    var useVideoThumbnail: Bool
    
    var view: any View {
        if case let .video(v) = self.data {
            if useVideoThumbnail, let url = URL(string: v.thumbnailURL) {
                return AsyncImage(url: url)
            }
            
            return BufferVideoPlayerView(videoPlayerVM: v)
        } else if case let .image(i) = self.data {
            return i
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            return EmptyView()
        }
    }
    
    init(data: PostMedia, useVideoThumbnail: Bool = false) {
        self.data = data
        self.useVideoThumbnail = useVideoThumbnail
    }
}
