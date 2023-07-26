//
//  SkillsGraph.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//


import SwiftUI

enum EventType: Int, CaseIterable {
    case one = 1
    case three = 3
    case platform = 5
}

enum SkillGraph: String, CaseIterable {
    case overall = "Overall"
    case one = "1-Meter"
    case three = "3-Meter"
    case platform = "Platform"
}

struct SkillsGraph: View {
    @StateObject private var parser = ProfileParser()
    var profileLink: String = ""
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    @State var oneMeterDict: [Int: Double] = [:]
    @State var threeMeterDict: [Int: Double] = [:]
    @State var platformDict: [Int: Double] = [:]
    @State var overallDict: [Int: Double] = [:]
    @State var oneMetrics: [Double] = []
    @State var threeMetrics: [Double] = []
    @State var platformMetrics: [Double] = []
    @State var overallMetrics: [Double] = []
    @State var selection: SkillGraph = .overall
    let diveTableData: [String: DiveData]? = getDiveTableData()
    var body: some View {
        VStack {
            SkillGraphSelectView(selection: $selection)
                .scaleEffect(0.8)
            ZStack {
                Graph()
                    .scaleEffect(0.5)
                    .rotationEffect(.degrees(-17.4))
                switch selection {
                case .overall:
                    Polygon(metrics: overallMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                case .one:
                    Polygon(metrics: oneMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                case .three:
                    Polygon(metrics: threeMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                case .platform:
                    Polygon(metrics: platformMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                }
                Group {
                    Text("Front")
                        .offset(x: screenWidth * 0.34, y: -screenHeight * 0.04)
                    Text("Back")
                        .offset(x: screenWidth * 0.22, y: screenHeight * 0.115)
                    Text("Reverse")
                        .offset(x: -screenWidth * 0.22, y: screenHeight * 0.115)
                    Text("Inward")
                        .offset(x: -screenWidth * 0.34, y: -screenHeight * 0.04)
                    Text("Twister")
                        .offset(y: -screenHeight * 0.14)
                }
                
            }
        }
        .frame(height: screenHeight * 0.4)
        .onAppear {
            Task {
                if parser.profileData.info == nil {
                    if await !parser.parseProfile(link: profileLink) {
                        print("Failed to parse profile")
                    }
                }
                if let stats = parser.profileData.diveStatistics {
                    let skill = SkillRating(diveStatistics: stats)
                    let divesByCategory = skill.getDiverStatsByCategory()
                    oneMeterDict = skillGraphMetrics(d: divesByCategory, height: EventType.one)
                    threeMeterDict = skillGraphMetrics(d: divesByCategory, height: EventType.three)
                    platformDict = skillGraphMetrics(d: divesByCategory, height: EventType.platform)
                    for i in 1..<6 {
                        divisor = 3.0
                        if platformDict[i] == 0.0 {
                            divisor = 2.0
                        }
                        let oneMScaled = oneMeterDict[i] ?? 0.0
                        let threeMScaled = threeMeterDict[i] ?? 0.0
                        let platformScaled = platformDict[i] ?? 0.0
                        let total = oneMScaled + threeMScaled + platformScaled
                        overallDict[i] = total / divisor
                    }
                    oneMetrics = diveDictToOrderedList(d: oneMeterDict)
                    threeMetrics = diveDictToOrderedList(d: threeMeterDict)
                    platformMetrics = diveDictToOrderedList(d: platformDict)
                    overallMetrics = diveDictToOrderedList(d: overallDict)
                }
            }
        }
    }
    
    func skillGraphMetrics(d: [Int: [DiveStatistic]], height: EventType) -> [Int:Double] {
        var result: [Int:Double] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        let sortedKeys = d.keys.sorted()
        
        for key in sortedKeys { //For Each Direction
            if let diveStatistics = d[key] {
                var ddFixedScore: Double = 0.0
                var judgeScore: Double = 0.0
                var counter = 0.0
                var total = 0.0
                
                for dive in diveStatistics { //Each Dive Within the Direction
                    let dd = getDiveDD(data: diveTableData ?? [:], forKey: dive.number, height: dive.height) ?? 0.0
                    guard dd != 0.0 else {
                        continue
                    }
                    ddFixedScore = dive.avgScore / dd
                    judgeScore = ddFixedScore / 3
                    if (height.rawValue == 5 && dive.height >= 5.0) || (dive.height == Double(height.rawValue)) {
                        total += judgeScore //Adding each individual judge score to the running total
                        counter += 1
                    }
                }
                if counter != 0 {
                    if result[key] == 0 {
                        result[key] = total / counter
                    } else {
                        result[key] = (result[key] ?? 0.0) + total / counter
                    }
                }
            }
        }
        return result
    }
    
    func diveDictToOrderedList(d: [Int:Double]) -> [Double] {
        var result: [Double] = []
        for i in 1..<6 {
            result.append((d[i] ?? 0.0) / 1.45) // Doing this to scale slightly larger
        }
        return result
    }
}

struct Pentagon : Shape {
    var sides : Int = 5
    
    func path(in rect : CGRect ) -> Path{
        // get the center point and the radius
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width / 2
        
        // get the angle in radian,
        // 2 pi divided by the number of sides
        
        let angle = (Double.pi * 2 / Double(sides))
        var path = Path()
        var startPoint = CGPoint(x: 0, y: 0)
        
        for side in 0 ..< sides {
            
            let x = center.x + CGFloat(cos(Double(side) * angle)) * CGFloat (radius)
            let y = center.y + CGFloat(sin(Double(side) * angle)) * CGFloat(radius)
            
            let vertexPoint = CGPoint( x: x, y: y)
            
            if (side == 0) {
                startPoint = vertexPoint
                path.move(to: startPoint )
            }
            else {
                path.addLine(to: vertexPoint)
            }
            
            // move back to starting point
            // needed for stroke
            if ( side == (sides - 1) ){
                path.addLine(to: startPoint)
            }
            
            // Add lines from center to each vertex
            path.move(to: center) // Move to the center
            path.addLine(to: vertexPoint) // Draw a line to the vertex
        }
        
        return path
    }
}

struct Polygon: Shape {
    var metrics: [Double] = []
    
    func path(in rect : CGRect ) -> Path{
        // get the center point and the radius
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = rect.width / 2
        
        // get the angle in radian,
        // 2 pi divided by the number of sides
        let angle = Double.pi * 2 / Double(metrics.count)
        var path = Path()
        var startPoint = CGPoint(x: 0, y: 0)
        
        for side in 0 ..< metrics.count {
            
            let x = center.x + CGFloat(cos(Double(side) * angle)) * CGFloat (radius * (metrics[side] / 5.0))
            let y = center.y + CGFloat(sin(Double(side) * angle)) * CGFloat(radius * (metrics[side] / 5.0))
            
            let vertexPoint = CGPoint( x: x, y: y)
            
            if (side == 0) {
                startPoint = vertexPoint
                path.move(to: startPoint )
            }
            else {
                path.addLine(to: vertexPoint)
            }
            
            // move back to starting point
            // needed for stroke
            if ( side == (metrics.count - 1) ){
                path.addLine(to: startPoint)
            }
        }
        
        return path
    }
}

struct Graph: View {
    private let screenWidth = UIScreen.main.bounds.width
    var body: some View {
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .frame(width : screenWidth * 0.2)
            .foregroundColor(.gray)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : screenWidth * 0.4)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : screenWidth * 0.6)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : screenWidth * 0.8)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : screenWidth)
    }
}

struct AdvancedSkillsGraphs: View {
    @Binding var oneMetrics: [Double]
    @Binding var threeMetrics: [Double]
    @Binding var platformMetrics: [Double]
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        ScrollView {
            VStack {
                BackgroundBubble() {
                    Text("One-Meter Skills")
                }
                .font(.title2).fontWeight(.semibold)
                ZStack{
                    Graph()
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Polygon(metrics: oneMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .frame(width: 500, height: 300)
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Text("Front")
                        .offset(x: screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Back")
                        .offset(x: screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Reverse")
                        .offset(x: -screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Inward")
                        .offset(x: -screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Twister")
                        .offset(y: -screenHeight * 0.15)
                }
                
                BackgroundBubble() {
                    Text("Three-Meter Skills")
                        .font(.title2).fontWeight(.semibold)
                }
                ZStack{
                    Graph()
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Polygon(metrics: threeMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .frame(width: 500, height: 300)
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Text("Front")
                        .offset(x: screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Back")
                        .offset(x: screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Reverse")
                        .offset(x: -screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Inward")
                        .offset(x: -screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Twister")
                        .offset(y: -screenHeight * 0.15)
                }
                
                BackgroundBubble() {
                    Text("Platform Skills")
                        .font(.title2).fontWeight(.semibold)
                }
                ZStack{
                    Graph()
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Polygon(metrics: platformMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .frame(width: 500, height: 300)
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                    Text("Front")
                        .offset(x: screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Back")
                        .offset(x: screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Reverse")
                        .offset(x: -screenWidth * 0.23, y: screenHeight * 0.12)
                    Text("Inward")
                        .offset(x: -screenWidth * 0.35, y: -screenHeight * 0.05)
                    Text("Twister")
                        .offset(y: -screenHeight * 0.15)
                }
            }
        }
    }
}

struct SkillGraphSelectView: View {
    @Binding var selection: SkillGraph
    
    private let cornerRadius: CGFloat = 30
    private let selectedGray = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.4)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Custom.darkGray)
                .shadow(radius: 10)
            HStack(spacing: 0) {
                ForEach(SkillGraph.allCases, id: \.self) { s in
                    ZStack {
                        // Weird padding stuff to have end options rounded on the outside edge
                        // only when selected
                        // https://stackoverflow.com/a/72435691/22068672
                        Rectangle()
                            .fill(selection == s ? selectedGray : .clear)
                            .padding(.trailing, s == SkillGraph.allCases.first
                                     ? cornerRadius
                                     : 0)
                            .padding(.leading, s == SkillGraph.allCases.last
                                     ? cornerRadius
                                     : 0)
                            .cornerRadius(s == SkillGraph.allCases.first ||
                                          s == SkillGraph.allCases.last
                                          ? cornerRadius
                                          : 0)
                            .padding(.trailing, s == SkillGraph.allCases.first
                                     ? -cornerRadius
                                     : 0)
                            .padding(.leading, s == SkillGraph.allCases.last
                                     ? -cornerRadius
                                     : 0)
                        Text(s.rawValue)
                    }
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .onTapGesture {
                        selection = s
                    }
                    if s != SkillGraph.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 50)
        .padding([.leading, .trailing])
    }
}
