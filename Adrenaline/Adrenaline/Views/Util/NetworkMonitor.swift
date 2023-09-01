//
//  NetworkMonitor.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 8/5/23.
//  https://medium.com/devtechie/detect-network-reachability-and-connection-type-in-swiftui-f58aa8740af8
//

import Foundation
import SwiftUI
import Network

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isCellular = false
    
    private let nwMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue.global()
    
    public func start() {
        nwMonitor.start(queue: workerQueue)
        nwMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isCellular = path.usesInterfaceType(.cellular)
            }
        }
    }
    
    public func stop() {
        nwMonitor.cancel()
    }
}

struct NotConnectedView: View {
    @Environment(\.colorScheme) var currentMode
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            currentMode == .light
            ? Color.white.ignoresSafeArea()
            : Color.black.ignoresSafeArea()
            
            BackgroundBubble(vPadding: 20) {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.primary)
                    VStack(spacing: 5) {
                        Text("Network connection seems to be offline.")
                        Text("Please check your connectivity.")
                    }
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing])
                }
                .frame(width: screenWidth * 0.9)
            }
            
        }
    }
}
