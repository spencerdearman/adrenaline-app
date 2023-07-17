//
//  LiveView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/4/23.
//

import SwiftUI

struct LiveView: View {
    @StateObject private var parser = LiveParser()
    @State var liveData: [String] = []
    
    var body: some View {
        ZStack{}
            .onAppear {
                Task {
                    await parser.parseWithDelay(urlString: "https://secure.meetcontrol.com/divemeets/system/livestats.php?event=stats-9037-3470-9-Started")
                    liveData = parser.liveData
                }
            }
    }
}
