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
                    
                    Text(meet.org?.uppercased() ?? "")
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle1\(id)", in: namespace)
                    
                    Text((meet.location?.uppercased() ?? "") + " - " + (meet.date?.uppercased() ?? ""))
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
        
                    // WORK ON LATER TO ADDRESS IF YOU WERE IN THE MEET OR NOT
//                    Divider()
//                        .foregroundColor(.secondary)
//                    
//                    HStack {
//                        LogoView(imageName: "Spencer")
//                            .shadow(radius: 10)
//                        Text("You attended, check your results now")
//                            .font(.footnote.weight(.medium))
//                            .foregroundStyle(.secondary)
//                    }
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
//    @State var selectedItem: String = ""
//    @State var showSheet: Bool = false
    @Binding var feedModel: FeedModel
    var id: String
    var namespace: Namespace.ID
    var meet: MeetBase
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            ScrollView {
                cover
                
                MeetPageView(meetLink: meet.link ?? "")
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
//            .sheet(isPresented: $showSheet) {
//                EntryPageView(entriesLink: selectedItem)
//            }
            CloseButtonWithFeedModel(feedModel: $feedModel)
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
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: scrollY > 0 ? 500 + scrollY : 500)
//            .background(AnimatedBlobView(
//                colors: [.white, Custom.coolBlue])
//                .frame(width: 400, height: 414)
//                .offset(x: 200, y: 0)
//                .scaleEffect(0.8))
//            .background(AnimatedBlobView(
//                colors: [.white, Custom.lightBlue, Custom.coolBlue])
//                .frame(width: 400, height: 414)
//                .offset(x: -50, y: 200)
//                .scaleEffect(0.7))
//            .background(AnimatedBlobView(
//                colors: [.white, Custom.lightBlue, Custom.medBlue, Custom.coolBlue])
//                .frame(width: 400, height: 414)
//                .offset(x: -100, y: 20)
//                .scaleEffect(1.6)
//                .rotationEffect(Angle(degrees: 60)))
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
            .overlay(
                VStack(alignment: .center, spacing: 16) {
                    Text(meet.name)
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .matchedGeometryEffect(id: "title\(id)", in: namespace)
                    
                    Text(meet.org ?? "")
                        .font(.title3).fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
                    
                    Text(meet.date?.uppercased() ?? "")
                        .font(.headline).bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "subtitle1\(id)", in: namespace)
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
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(20)
            )
        }
        .frame(height: 500)
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
