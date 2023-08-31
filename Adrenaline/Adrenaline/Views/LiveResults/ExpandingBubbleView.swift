//
//  ExpandingBubbleView.swift
//  DiveMeets
//
//  Created by Spencer Dearman on 6/26/23.
//
//
//import SwiftUI
//
//struct HomeBubbleView: View{
//    @Namespace var mainspace
//    let gridItems = [GridItem(.adaptive(minimum: 300))]
//    @Binding var diveTable: [[String]]
//    @Binding var starSelected: Bool
//    @Binding var abBoardEvent: Bool
//    @State var expandedIndex: String = "-1"
//    
//    var body: some View {
//        if starSelected {
//            BackgroundBubble(vPadding: 25, hPadding: 25) {
//                Text("Live Rankings")
//                    .font(.title2).bold()
//                    .matchedGeometryEffect(id: "ranking", in: mainspace)
//            }
//        } else if !abBoardEvent {
//            BackgroundBubble(vPadding: 25, hPadding: 25) {
//                Text("Live Rankings")
//                    .font(.title2).bold()
//                    .matchedGeometryEffect(id: "ranking", in: mainspace)
//            }
//        }
//        ZStack{
//            ScrollView {
//                LazyVGrid(columns: gridItems, spacing: 5) {
//                    ForEach(diveTable, id: \.self) { elem in
//                        HomeView(bubbleData: elem, starSelected: $starSelected,
//                                 expandedIndex: $expandedIndex, abBoardEvent: $abBoardEvent)
//                    }
//                }
//                .padding(20)
//            }
//        }
//    }
//}
//
//struct HomeView: View {
//    @State var hasScrolled = false
//    @Namespace var namespace
//    @State var show: Bool = false
//    @State var bubbleData: [String]
//    @Binding var starSelected: Bool
//    @Binding var expandedIndex: String
//    @Binding var abBoardEvent: Bool
//    
//    init(bubbleData: [String], starSelected: Binding<Bool>, expandedIndex: Binding<String>,
//         abBoardEvent: Binding<Bool>) {
//        self.bubbleData = bubbleData
//        self._starSelected = starSelected
//        self._expandedIndex = expandedIndex
//        self._abBoardEvent = abBoardEvent
//    }
//    
//    var body: some View{
//        if show {
//            OpenTileView(namespace: namespace, show: $show, bubbleData: $bubbleData,
//                         abBoardEvent: $abBoardEvent)
//                .onTapGesture {
//                    if expandedIndex == (abBoardEvent ? bubbleData[3] : bubbleData[1]){
//                        if !abBoardEvent {
//                            expandedIndex = "-1"
//                            starSelected = false
//                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
//                                show.toggle()
//                            }
//                        }
//                    }
//                }
//                .shadow(radius: 5)
//        } else {
//            ClosedTileView(namespace: namespace, show: $show, bubbleData: $bubbleData,
//                           abBoardEvent: $abBoardEvent)
//                .onTapGesture {
//                    if expandedIndex == "-1" && !abBoardEvent {
//                        expandedIndex = abBoardEvent ? bubbleData[3] : bubbleData[1]
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
//                            starSelected = true
//                            show.toggle()
//                        }
//                    }
//                }
//        }
//    }
//}
//
//struct ClosedTileView: View {
//    @Environment(\.colorScheme) var currentMode
//    var namespace: Namespace.ID
//    @Binding var show: Bool
//    @Binding var bubbleData: [String]
//    @Binding var abBoardEvent: Bool
//    
//    //(Left to dive, order, last round place, last round score, current place,
//    //current score, name, last dive average, event average score, avg round score
//    
//    var body: some View{
//        VStack{
//            Spacer()
//        }
//        .frame(maxWidth: .infinity)
//        .foregroundStyle(.white)
//        .background(
//            Custom.darkGray.matchedGeometryEffect(id: "background", in: namespace)
//        )
//        .mask(
//            RoundedRectangle(cornerRadius: 30, style: .continuous)
//                .matchedGeometryEffect(id: "mask", in: namespace)
//        )
//        .shadow(radius: 5)
//        .overlay(
//            ZStack {
//                VStack(alignment: .leading, spacing: 12) {
//                    HStack {
//                        VStack(alignment: .leading) {
//                            Text(abBoardEvent
//                                 ? bubbleData[3].components(separatedBy: " ").first ?? ""
//                                 : bubbleData[6].components(separatedBy: " ").first ?? "")
//                                .matchedGeometryEffect(id: "firstname", in: namespace)
//                            let fullSecondString = bubbleData[3].components(separatedBy: " ").last ?? ""
//                            let lastName = fullSecondString.components(separatedBy: "(").first
//                            let team = fullSecondString.components(separatedBy: "(").last
//                            Text(abBoardEvent
//                                 ? ((lastName ?? "") + " (" + (team ?? ""))
//                                 : bubbleData[6].components(separatedBy: " ").last ?? "")
//                                .matchedGeometryEffect(id: "lastname", in: namespace)
//                        }
//                        .lineLimit(2)
//                        .font(.title2)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        if !abBoardEvent && (Bool(bubbleData[0]) ?? false) {
//                            Image(systemName: "checkmark")
//                                .offset(x: -10)
//                                .matchedGeometryEffect(id: "checkmark", in: namespace)
//                        }
//                        ZStack {
//                            Rectangle()
//                                .foregroundColor(Custom.accentThinMaterial)
//                                .mask(RoundedRectangle(cornerRadius: 60, style: .continuous))
//                                .shadow(radius: 2)
//                                .frame(width: 200, height: 40)
//                            Text("Current Score: " + (abBoardEvent ? bubbleData[1] : bubbleData[5]))
//                                .dynamicTypeSize(.xSmall ... .xLarge)
//                                .fontWeight(.semibold)
//                                .matchedGeometryEffect(id: "currentScore", in: namespace)
//                        }
//                        
//                    }
//                    
//                    HStack {
//                        Text("Current Place: " + (abBoardEvent ? bubbleData[0] : bubbleData[4]))
//                            .fontWeight(.semibold)
//                            .matchedGeometryEffect(id: "currentPlace", in: namespace)
//                        Spacer()
//                        if !abBoardEvent {
//                            Text("Last Round Place: " + bubbleData[2])
//                                .font(.footnote.weight(.semibold))
//                                .matchedGeometryEffect(id: "previous", in: namespace)
//                        } else {
//                            Text("Board: " + bubbleData[11])
//                                .foregroundColor(.primary)
//                                .font(.footnote.weight(.semibold))
//                                .matchedGeometryEffect(id: "board", in: namespace)
//                        }
//                    }
//                }
//                .padding(20)
//            }
//        )
//        .frame(height: 120)
//        .padding(1)
//    }
//}
//
//struct OpenTileView: View {
//    @Environment(\.colorScheme) var currentMode
//    var namespace: Namespace.ID
//    @Binding var show: Bool
//    @Binding var bubbleData: [String]
//    @Binding var abBoardEvent: Bool
//    
//    private var bgColor: Color {
//        currentMode == .light ? Custom.darkGray : Custom.darkGray
//    }
//    
//    private var txtColor: Color {
//        currentMode == .light ? .black : .white
//    }
//    
//    var body: some View{
//        
//        VStack{
//            Spacer()
//            VStack(alignment: .leading, spacing: 12){
//                HStack {
//                    VStack(alignment: .leading) {
//                        VStack(alignment: .leading) {
//                            Text(abBoardEvent
//                                 ? bubbleData[3].components(separatedBy: " ").first ?? ""
//                                 : bubbleData[6].components(separatedBy: " ").first ?? "")
//                                .matchedGeometryEffect(id: "firstname", in: namespace)
//                            Text(abBoardEvent
//                                 ? bubbleData[3].components(separatedBy: " ").last ?? ""
//                                 : bubbleData[6].components(separatedBy: " ").last ?? "")
//                                .matchedGeometryEffect(id: "lastname", in: namespace)
//                        }
//                        .font(.largeTitle)
//                        .foregroundColor(txtColor)
//                        .lineLimit(2)
//                        HStack {
//                            Text("Current Place: " + (abBoardEvent ? bubbleData[0] : bubbleData[4]))
//                                .scaledToFit()
//                                .fontWeight(.semibold)
//                                .matchedGeometryEffect(id: "currentPlace", in: namespace)
//                            if !abBoardEvent && (Bool(bubbleData[0]) ?? false) {
//                                Image(systemName: "checkmark")
//                                    .matchedGeometryEffect(id: "checkmark", in: namespace)
//                            }
//                        }
//                        .foregroundColor(txtColor)
//                        Text("Current Score: " + (abBoardEvent ? bubbleData[1] : bubbleData[5]))
//                            .font(.footnote.weight(.semibold)).scaledToFit()
//                            .foregroundColor(txtColor)
//                            .matchedGeometryEffect(id: "currentScore", in: namespace)
//                        if abBoardEvent {
//                            Text("Board: " + bubbleData[11])
//                                .foregroundColor(.primary)
//                                .font(.footnote.weight(.semibold))
//                                .matchedGeometryEffect(id: "board", in: namespace)
//                        }
//                    }
//                    NavigationLink {
//                        ProfileView(profileLink: abBoardEvent ? bubbleData[4] : bubbleData[7])
//                    } label: {
//                        MiniProfileImage(diverID: abBoardEvent
//                                         ? String(bubbleData[4].components(separatedBy: "=").last ?? "")
//                                         : String(bubbleData[7].components(separatedBy: "=").last ?? ""),
//                                         width: 150, height: 200)
//                            .scaledToFit()
//                            .padding(.horizontal)
//                            .shadow(radius: 10)
//                    }
//                }
//                if !abBoardEvent {
//                    ZStack{
//                        Rectangle()
//                            .foregroundColor(Custom.accentThinMaterial)
//                            .mask(RoundedRectangle(cornerRadius: 30, style: .continuous))
//                            .matchedGeometryEffect(id: "blur", in: namespace)
//                            .shadow(radius: 10)
//                        VStack(spacing: 10){
//                            Text("Advanced Statistics")
//                                .font(.title2)
//                                .fontWeight(.bold).underline()
//                            HStack{
//                                Text("Order: " + bubbleData[1])
//                                Text("Last Round Place: " + bubbleData[2])
//                                    .matchedGeometryEffect(id: "previous", in: namespace)
//                            }
//                            .fontWeight(.semibold)
//                            Text("Last Round Score: " + bubbleData[3])
//                                .fontWeight(.semibold)
//                            Text("Last Dive Average: " + bubbleData[8])
//                                .fontWeight(.semibold)
//                            Text("Average Event Score: " + bubbleData[9])
//                                .fontWeight(.semibold)
//                            Text("Average Round Score: " + bubbleData[10])
//                                .fontWeight(.semibold)
//                        }
//                        .foregroundColor(txtColor)
//                    }
//                    
//                }
//                Spacer()
//            }
//            .padding(20)
//        }
//        .foregroundStyle(.black)
//        .background(
//            Custom.darkGray.matchedGeometryEffect(id: "background", in: namespace)
//        )
//        .mask(
//            RoundedRectangle(cornerRadius: 40, style: .continuous)
//                .matchedGeometryEffect(id: "mask", in: namespace)
//        )
//        .frame(height: abBoardEvent ? 275 : 500)
//    }
//}
