//
//  SkillsGraph.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//


import SwiftUI

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
    let diveTableData: [String: DiveData]? = getDiveTableData()
    var body: some View {
        VStack {
            ZStack {
                Graph()
                    .scaleEffect(0.5)
                    .rotationEffect(.degrees(-17.4))
                NavigationLink {
                    AdvancedSkillsGraphs(oneMetrics: $oneMetrics, threeMetrics: $threeMetrics, platformMetrics: $platformMetrics)
                } label: {
                    Polygon(metrics: overallMetrics)
                        .fill(Custom.medBlue.opacity(0.5))
                        .frame(width: 500)
                        .scaleEffect(0.5)
                        .rotationEffect(.degrees(-17.4))
                }
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
            .offset(y: -300)
        }
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
                    oneMeterDict = skillGraphMetrics(d: divesByCategory, height: 1)
                    threeMeterDict = skillGraphMetrics(d: divesByCategory, height: 3)
                    platformDict = skillGraphMetrics(d: divesByCategory, height: 5)
                    var divisor = 3.0
                    for i in 1..<6 {
                        var divisor = 3.0
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
    
    func skillGraphMetrics(d: [Int: [DiveStatistic]], height: Int) -> [Int:Double] {
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
                    if dd == 0.0 {
                        continue
                    }
                    ddFixedScore = dive.avgScore / (getDiveDD(data: diveTableData ?? [:], forKey: dive.number, height: dive.height) ?? 0.0)
                    judgeScore = ddFixedScore / 3
                    if (height == 5 && dive.height >= 5.0) || (dive.height == Double(height)) {
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
    var body: some View {
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .frame(width : 100)
            .foregroundColor(.gray)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : 200)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : 300)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : 400)
        Pentagon()
            .stroke(.primary, lineWidth: 2)
            .foregroundColor(.gray)
            .frame(width : 500)
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

