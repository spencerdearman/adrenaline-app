//
//  ExpandedResultsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/14/24.
//

import SwiftUI

struct ExpandedResultsView: View {
    @State private var newResults: [RecentResultObject] = []
    @Namespace var namespace
    @Binding var results: [RecentResultObject]
    @State private var feedModel: FeedModel = FeedModel()
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        ZStack {
            if feedModel.showTile {
                ForEach($newResults) { result in
                    if result.recentResult.0.id == feedModel.selectedItem {
                        AnyView(result.recentResult.0.expandedView.wrappedValue)
                    }
                }
            }
            
            ScrollView {
                Rectangle()
                    .frame(width: 100, height: screenHeight * 0.15)
                    .opacity(0)
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach($newResults) { result in
                        AnyView(result.recentResult.0.collapsedView.wrappedValue)
                    }
                }
                .padding(.horizontal, 20)
                .offset(y: -80)
            }
            .dynamicTypeSize(.xSmall ... .xxLarge)
        }
        .onChange(of: feedModel.selectedItem) {
            print("selected Item:", feedModel.selectedItem)
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
