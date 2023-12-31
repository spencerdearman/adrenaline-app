//
//  PostMediaItem.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/24/23.
//

import SwiftUI
import AVKit
import CachedAsyncImage


enum PostMedia {
    case video(VideoPlayerViewModel)
    case localVideo(AVPlayer)
    case image(Image)
    case asyncImage(CachedAsyncImage<AnyView>)
}

struct PostMediaItem: Identifiable {
    var id: String
    var data: PostMedia
    var useVideoThumbnail: Bool
    var playVideoOnAppear: Bool
    var videoIsLooping: Bool
    
    init(id: String = UUID().uuidString, data: PostMedia, useVideoThumbnail: Bool = false,
         playVideoOnAppear: Bool = false, videoIsLooping: Bool = false) {
        self.id = id
        self.data = data
        self.useVideoThumbnail = useVideoThumbnail
        self.playVideoOnAppear = playVideoOnAppear
        self.videoIsLooping = videoIsLooping
    }
    
    var view: any View {
        if case let .video(v) = self.data {
            if useVideoThumbnail, let url = URL(string: v.thumbnailURL) {
                return CachedAsyncImage(url: url, urlCache: .imageCache)
            }
            
            return BufferVideoPlayerView(videoPlayerVM: v, playOnAppear: playVideoOnAppear,
                                         isLooping: videoIsLooping)
        } else if case let .localVideo(v) = self.data {
            let url = (v.currentItem?.asset as? AVURLAsset)?.url
            let isVertical = isVerticalLocalVideo(url: url?.absoluteString ?? "")
            return VideoPlayer(player: v)
                .aspectRatio(isVertical
                             ? CGSize(width: 9, height: 16)
                             : CGSize(width: 16, height: 9), contentMode: .fit)
        } else if case let .image(i) = self.data {
            return i
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if case let .asyncImage(i) = self.data {
            return i
        } else {
            return EmptyView()
        }
    }
}
