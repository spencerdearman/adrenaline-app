//
//  ExpandedResultsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/14/24.
//

import SwiftUI

struct ExpandedResultsView: View {
    @State private var selectedResult: MeetFeedItem? = nil
    @State private var newResults: [RecentResultObject] = []
    @Namespace var namespace
    @Binding var results: [RecentResultObject]
    @Binding var feedModel: FeedModel
    
    private let screenHeight = UIScreen.main.bounds.height
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        ZStack {
            if feedModel.showTile {
                ForEach($newResults, id: \.id) { result in
                    let (item, _) = result.recentResult.wrappedValue
                    if item.id == selectedResult?.id {
                        AnyView(item.expandedView)
                    }
                }
            }
            
            ScrollView {
                // Scrolling Detection
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("scroll")).minY
                    Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
                }
                
                Rectangle()
                    .frame(width: 100, height: screenHeight * 0.15)
                    .opacity(0)
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach($newResults, id: \.id) { result in
                        let (item, _) = result.recentResult.wrappedValue
                        AnyView(item.collapsedView)
                            .onTapGesture {
                                selectedResult = item
                                feedModel.showTile = true
                            }
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: -80)
            }
            .dynamicTypeSize(.xSmall ... .xxLarge)
        }
        .onChange(of: results, initial: true) {
            newResults = results.map {
                RecentResultObject(id: $0.id,
                             recentResult: (MeetFeedItem(meet: $0.recentResult.0.meet,
                                                         namespace: namespace,
                                                         feedModel: $feedModel), $0.recentResult.1))
            }
        }
    }
}
