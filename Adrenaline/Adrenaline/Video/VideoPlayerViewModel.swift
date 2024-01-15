//
//  VideoPlayerViewModel.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/20/23.
//  https://github.com/create-with-swift/streaming-with-swiftui/blob/main/StreamingApp/VideoPlayerVM.swift
//

import Foundation
import Combine
import AVKit

final class VideoPlayerViewModel: ObservableObject {
    @Published var selectedResolution: Resolution
    @Published private var shouldLowerResolution = false
//    @Published var disableReplacements = false
    
    let player = AVPlayer()
    private let video: VideoItem
    private var subscriptions: Set<AnyCancellable> = []
    private var timeObserverToken: Any?
    
    var name: String { video.name }
    var namePlusResolution: String { video.name + " at " + selectedResolution.displayValue }
    var thumbnailURL: String { video.thumbnailURL }
    
    init(video: VideoItem, initialResolution: Resolution) {
        self.video = video
        self.selectedResolution = initialResolution
        self.replaceItem(with: self.selectedResolution)
        
//        $shouldLowerResolution
//            .dropFirst()
//            .filter({ $0 == true })
//            .sink(receiveValue: { [weak self] _ in
//                guard let self = self else { return }
//                self.lowerResolutionIfPossible()
//            })
//            .store(in: &subscriptions)
        
//        $selectedResolution
//            .sink(receiveValue: { [weak self] resolution in
//                guard let self = self else { return }
////                self.replaceItem(with: resolution)
//                self.setObserver()
//            })
//            .store(in: &subscriptions)
    }
    
    deinit {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
    }
    
    var isVertical: Bool {
        video.isVertical
    }
    
    private func setObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        
        // CMTime => value / timescale
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.main, using: { [weak self] time in
            guard let self = self,
                  let currentItem = self.player.currentItem else { return }
            
            guard currentItem.isPlaybackBufferFull == false else {
                self.shouldLowerResolution = false
                return
            }
            
            if currentItem.status == AVPlayerItem.Status.readyToPlay {
                self.shouldLowerResolution = (!currentItem.isPlaybackLikelyToKeepUp && !currentItem.isPlaybackBufferEmpty)
            }
        })
    }
    
    private func lowerResolutionIfPossible() {
        guard let newResolution = Resolution(rawValue: selectedResolution.rawValue - 1) else { return }
        selectedResolution = newResolution
    }
    
    private func replaceItem(with newResolution: Resolution) {
//        print("replacing \(self.selectedResolution.displayValue) with \(newResolution.displayValue)")
        guard let stream = self.video.streams.first(where: { $0.resolution == newResolution }) else { return }
        let currentTime: CMTime
        if let currentItem = player.currentItem {
            currentTime = currentItem.currentTime()
        } else {
            currentTime = .zero
        }
        
        player.replaceCurrentItem(with: AVPlayerItem(url: stream.streamURL))
        player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

extension VideoPlayerViewModel {
    static var `default`: Self {
        .init(video: VideoItem(), initialResolution: .p540)
    }
}
