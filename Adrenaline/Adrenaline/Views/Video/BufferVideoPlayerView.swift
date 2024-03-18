//
//  BufferVideoPlayerView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 10/20/23.
//

import SwiftUI
import AVKit

struct BufferVideoPlayerView: View {
    @StateObject var videoPlayerVM: VideoPlayerViewModel
    @State private var showResolutions = false
    var playOnAppear: Bool
    var isLooping: Bool
    var debugMode: Bool = false
    
    // State to manage if the video player is centered
    @State private var isCenterAlignedAndMidScreen = false
    
    var body: some View {
        GeometryReader { fullGeometry in // Full view size for comparison
            ZStack {
                VStack(alignment: .leading) {
                    if debugMode {
                        Button("Change resolution") {
                            withAnimation {
                                showResolutions.toggle()
                            }
                        }
                        .font(Font.body.bold())
                    }
                    
                    VideoPlayer(player: videoPlayerVM.player) {
                        if debugMode {
                            Text(videoPlayerVM.namePlusResolution)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(8)
                        }
                    }
                    .aspectRatio(videoPlayerVM.isVertical ? CGSize(width: 9, height: 16) : CGSize(width: 16, height: 9), contentMode: .fit)
                    .onAppear {
                        if playOnAppear {
                            videoPlayerVM.player.play()
                        }
                    }
                    .onChange(of: isCenterAlignedAndMidScreen) { aligned in
                        if aligned {
                            videoPlayerVM.player.play()
                        } else {
                            videoPlayerVM.player.pause()
                        }
                    }
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            // Calculate if the video player is centered
                            let playerMidY = geo.frame(in: .global).midY
                            let screenMidY = fullGeometry.size.height / 2
                            let screenQuarterHeight = fullGeometry.size.height / 4
                            
                            isCenterAlignedAndMidScreen = abs(playerMidY - screenMidY) < screenQuarterHeight
                        }
                    })
                }
                .onAppear {
                    if isLooping {
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                            videoPlayerVM.player.seek(to: .zero)
                            videoPlayerVM.player.play()
                        }
                    }
                }
                .onDisappear {
                    videoPlayerVM.player.pause()
                    if isLooping {
                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
                    }
                }
                
                if debugMode && showResolutions {
                    resolutionPicker
                }
            }
        }
    }
    
    @ViewBuilder
    private var resolutionPicker: some View {
        VStack(spacing: 20) {
            Spacer()
            ForEach(Resolution.allCases) { resolution in
                Button(resolution.displayValue, action: {
                    withAnimation {
                        videoPlayerVM.selectedResolution = resolution
                        showResolutions.toggle()
                    }
                })
            }
            
            Button(action: {
                withAnimation {
                    showResolutions.toggle()
                }
            }, label: {
                Image(systemName: "xmark.circle")
                    .imageScale(.large)
            })
            .padding(.top)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .transition(.move(edge: .bottom))
    }
}
