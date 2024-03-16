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
    var meet: MeetBase
    
    init(meet: MeetBase, namespace: Namespace.ID, feedModel: Binding<FeedModel>) {
        self.meet = meet
        super.init()
        self.collapsedView = MeetFeedItemCollapsedView(feedModel: feedModel, id: self.id,
                                                       namespace: namespace,
                                                       meet: self.meet)
        self.expandedView = MeetFeedItemExpandedView(feedModel: feedModel, id: self.id,
                                                     namespace: namespace,
                                                     meet: self.meet)
    }
}

struct MeetFeedItemCollapsedView: View {
    @Environment(\.colorScheme) var currentMode
    @State var appear = [false, false, false]
    @Binding var feedModel: FeedModel
    var id: String
    var namespace: Namespace.ID
    var meet: MeetBase
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15),
                        radius: 15, x: 0, y: 30)
                .matchedGeometryEffect(id: "background\(id)", in: namespace)
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text(meet.name)
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "title\(id)", in: namespace)
                    
                    if meet.org != "" {
                        Text(meet.org?.uppercased() ?? "")
                            .font(.footnote).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.primary.opacity(0.7))
                            .matchedGeometryEffect(id: "subtitle1\(id)", in: namespace)
                    }
                    
                    Text((meet.location?.uppercased() ?? "") + " - " + (meet.date?.uppercased() ?? ""))
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
                        .accessibilityElement(children: .combine)
                }
                .padding(20)
                .padding(.vertical, 10)
            }
        }
        .onTapGesture {
            withAnimation(.openCard) {
                feedModel.showTile = true
                feedModel.selectedItem = id
            }
        }
        .frame(width: screenWidth * 0.9, height: screenHeight * 0.25)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct MeetFeedItemExpandedView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    @State var viewState: CGSize = .zero
    @State var showSection = false
    @State var appear = [false, false, false]
    @State private var titleSize: CGSize = .zero
    @Binding var feedModel: FeedModel
    var id: String
    var namespace: Namespace.ID
    var meet: MeetBase
    
    var titleBaseHeight: CGFloat {
        (meet.resultsLink == nil || meet.resultsLink == "") ? 250 : 175
    }
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private let outerTitlePadding: CGFloat = 20
    
    var body: some View {
        ZStack {
            ScrollView {
                cover
                
                if (meet.resultsLink == nil || meet.resultsLink == "") {
                    MeetPageView(meetLink: meet.link ?? "")
                } else {
                    MeetPageView(meetLink: meet.link ?? "", infoLink: meet.resultsLink ?? "")
                }
                //MeetPageView(meetLink: meet.link ?? "")
            }
            .coordinateSpace(name: "scroll")
            .background(currentMode == .light ? Color.white : Color.black)
            .mask(RoundedRectangle(cornerRadius: appear[0] ? 0 : 30))
            .mask(RoundedRectangle(cornerRadius: viewState.width / 3))
            .modifier(OutlineModifier(cornerRadius: viewState.width / 3))
            .scaleEffect(-viewState.width/500 + 1)
            .background(.ultraThinMaterial)
            .gesture(feedModel.isAnimated ? drag : nil)
            .ignoresSafeArea()
        }
        .frame(maxWidth: screenWidth)
        .zIndex(1)
        .onAppear {
            fadeIn()
        }
        .onChange(of: feedModel.showTile) {
            fadeOut()
        }
    }
    
    var cover: some View {
        GeometryReader { proxy in
            let scrollY = proxy.frame(in: .named("scroll")).minY
            VStack {
                CloseButtonWithFeedModel(feedModel: $feedModel)
                    .offset(y: scrollY > 0 ? -scrollY : 0)
                
                ChildSizeReader(size: $titleSize) {
                    VStack(alignment: .center, spacing: 16) {
                        Text(meet.name)
                            .font(.title).bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        if meet.org != "" {
                            Text(meet.org ?? "")
                                .font(.title3).fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text(meet.date?.uppercased() ?? "")
                            .font(.headline).bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.primary)
                    }
                    .padding(20)
                    .padding(.vertical, 10)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .cornerRadius(30)
                            .blur(radius: 30)
                            .matchedGeometryEffect(id: "blur\(id)", in: namespace)
                            .opacity(appear[0] ? 0 : 1)
                    )
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 30)
                            .opacity(appear[0] ? 1 : 0)
                    )
                    .offset(y: scrollY > 0 ? -scrollY * 1.8 : 0)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .frame(minHeight: titleBaseHeight, maxHeight: 350)
                    .padding(outerTitlePadding)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .offset(y: ((meet.resultsLink == nil || meet.resultsLink == "")
                            ? screenHeight * -0.1
                            : screenHeight * -0.182)
                        + (titleSize.height - titleBaseHeight - outerTitlePadding * 2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: scrollY > 0 ? 500 + scrollY : 500)
            .background(
                Image("WaveBackground")
                    .matchedGeometryEffect(id: "background\(id)", in: namespace)
                    .mask(RoundedRectangle(cornerRadius: 30))
                    .offset(y: scrollY > 0 ? -scrollY : 0)
                    .scaleEffect(scrollY > 0 ? scrollY / 1000 + 1.2 : 1.2)
                    .blur(radius: scrollY > 0 ? scrollY / 10 : 0)
                    .accessibility(hidden: true)
                    .ignoresSafeArea()
            )
            .mask(
                RoundedRectangle(cornerRadius: appear[0] ? 0 : 30)
                    .matchedGeometryEffect(id: "mask\(id)", in: namespace)
                    .offset(y: scrollY > 0 ? -scrollY : 0)
            )
        }
        .frame(height: 109 + titleSize.height)
    }
    
    func close() {
        withAnimation {
            viewState = .zero
        }
        withAnimation(.closeCard.delay(0.2)) {
            feedModel.showTile = false
            feedModel.selectedItem = ""
        }
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onChanged { value in
                guard value.translation.width > 0 else { return }
                
                if value.startLocation.x < 100 {
                    withAnimation {
                        viewState = value.translation
                    }
                }
                
                if viewState.width > 120 {
                    close()
                }
            }
            .onEnded { value in
                if viewState.width > 80 {
                    close()
                } else {
                    withAnimation(.openCard) {
                        viewState = .zero
                    }
                }
            }
    }
    
    func fadeIn() {
        withAnimation(.easeOut.delay(0.3)) {
            appear[0] = true
        }
        withAnimation(.easeOut.delay(0.4)) {
            appear[1] = true
        }
        withAnimation(.easeOut.delay(0.5)) {
            appear[2] = true
        }
    }
    
    func fadeOut() {
        withAnimation(.easeIn(duration: 0.1)) {
            appear[0] = false
            appear[1] = false
            appear[2] = false
        }
    }
}
