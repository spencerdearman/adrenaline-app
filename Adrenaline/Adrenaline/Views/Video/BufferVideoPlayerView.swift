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
    
    var body: some View {
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
                .aspectRatio(videoPlayerVM.isVertical
                             ? CGSize(width: 9, height: 16)
                             : CGSize(width: 16, height: 9), contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .onAppear {
                    if playOnAppear {
                        videoPlayerVM.player.play()
                    }
                        
                    if isLooping {
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                               object: nil, queue: .main) { _ in
                            videoPlayerVM.player.seek(to: .zero)
                            videoPlayerVM.player.play()
                        }
                    }
                }
                .onDisappear {
                    videoPlayerVM.player.pause()
                }
            }
            .padding()
            
            if debugMode && showResolutions {
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
    }
}
