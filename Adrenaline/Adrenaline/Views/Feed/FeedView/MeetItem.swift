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
    @State var appear = [false, false, false]
    @Binding var feedModel: FeedModel
    
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
                    
                    Text("Meet Location - Date Range".uppercased())
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
                    
                    Text("Basic Results are going to go here or something to lure the person in")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "description\(id)", in: namespace)
                    
                    Divider()
                        .foregroundColor(.secondary)
                    
                    HStack {
                        LogoView(imageName: "Spencer")
                            .shadow(radius: 10)
                        Text("You attended, check your results now")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
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
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.25)
        .padding()
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct MeetFeedItemExpandedView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.presentationMode) var presentationMode
    var id: String
    var namespace: Namespace.ID
    var meet: MeetEvent
    var isAnimated = true
    @State var viewState: CGSize = .zero
    @State var showSection = false
    @State var appear = [false, false, false]
    @Binding var feedModel: FeedModel
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            ScrollView {
                cover
            }
            .coordinateSpace(name: "scroll")
            .background(Color("Background"))
            .mask(RoundedRectangle(cornerRadius: appear[0] ? 0 : 30))
            .mask(RoundedRectangle(cornerRadius: viewState.width / 3))
            .modifier(OutlineModifier(cornerRadius: viewState.width / 3))
            .scaleEffect(-viewState.width/500 + 1)
            .background(.ultraThinMaterial)
            .gesture(isAnimated ? drag : nil)
            .ignoresSafeArea()
            
            Button {
                isAnimated ?
                withAnimation(.closeCard) {
                    feedModel.showTile = false
                    feedModel.selectedItem = ""
                }
                : presentationMode.wrappedValue.dismiss()
            } label: {
                CloseButton()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(20)
            .ignoresSafeArea()
            
            LogoView(imageName: "Spencer")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .matchedGeometryEffect(id: "logo\(id)", in: namespace)
                .ignoresSafeArea()
                .accessibility(hidden: true)
        }
        .frame(maxWidth: screenWidth)
        .zIndex(1)
        .onAppear {
            fadeIn()
        }
        .onChange(of: feedModel.showTile) { show in
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
            .background(
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.white,
                                                                     Custom.lightBlue,
                                                                     Custom.medBlue,
                                                                     Custom.coolBlue,
                                                                     Custom.darkBlue]),
                                         startPoint: .bottom, endPoint: .top))
                    .matchedGeometryEffect(id: "background\(id)", in: namespace)
                    .mask(RoundedRectangle(cornerRadius: 30))
                    .offset(y: scrollY > 0 ? -scrollY : 0)
                    .scaleEffect(scrollY > 0 ? scrollY / 1000 + 1 : 1)
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
                VStack(alignment: .leading, spacing: 16) {
                    Text(meet.name)
                        .font(.title).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "title\(id)", in: namespace)
                    
                    Text("Meet Location - Date Range".uppercased())
                        .font(.footnote).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "subtitle\(id)", in: namespace)
                    
                    Text("Basic Results are going to go here or something to lure the person in")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.primary.opacity(0.7))
                        .matchedGeometryEffect(id: "description\(id)", in: namespace)
                    
                    Divider()
                        .foregroundColor(.secondary)
                        .opacity(appear[1] ? 1 : 0)
                    
                    HStack {
                        LogoView(imageName: "Spencer")
                        Text("You attended, check your results now")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(appear[1] ? 1 : 0)
                    .accessibilityElement(children: .combine)
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
                    .offset(y: 100)
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
