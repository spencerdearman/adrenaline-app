//
//  MeetItem.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import UIKit
import AVKit

class MeetFeedItem: FeedItem {
    var meet: MeetEvent
    
    init(meet: MeetEvent, namespace: Namespace.ID, feedModel: Binding<FeedModel>) {
        self.meet = meet
        super.init()
        self.collapsedView = MeetFeedItemCollapsedView(id: self.id, namespace: namespace,
                                                       meet: self.meet, feedModel: feedModel)
        self.expandedView = MeetFeedItemExpandedView(id: self.id, namespace: namespace,
                                                     meet: self.meet, feedModel: feedModel)
    }
}

struct MeetFeedItemCollapsedView: View {
    var id: String
    var namespace: Namespace.ID
    var meet: MeetEvent
    @Binding var feedModel: FeedModel
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.white.opacity(0.95))
                .cornerRadius(30)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15), radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            VStack {
                Text(meet.name)
                    .font(.title).fontWeight(.bold)
                    .matchedGeometryEffect(id: "title" + id, in: namespace)
            }
        }
        .onTapGesture {
            withAnimation(.openCard) {
                feedModel.showDetail = true
                feedModel.selectedItem = id
            }
        }
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.25)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct MeetFeedItemExpandedView: View {
    @Environment(\.presentationMode) var presentationMode
    var id: String
    var namespace: Namespace.ID
    var meet: MeetEvent
    @Binding var feedModel: FeedModel
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Custom.darkGray)
                .cornerRadius(40)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15), radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background" + id, in: namespace)
            VStack {
                Text(meet.name)
                    .font(.title).fontWeight(.bold)
                    .matchedGeometryEffect(id: "title" + id, in: namespace)
            }
        }
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.5)
//        .fixedSize(horizontal: true, vertical: false)
    }
}
