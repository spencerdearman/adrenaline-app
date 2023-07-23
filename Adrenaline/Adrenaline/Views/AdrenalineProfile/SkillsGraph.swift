//
//  SkillsGraph.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//


import SwiftUI

struct SkillsGraph: View {
    @StateObject private var parser = ProfileParser()
    @State private var profileLink = "https://secure.meetcontrol.com/divemeets/system/profile.php?number=51197"
    @State var metrics: [Double] = [4.0, 4.6, 3.56, 3.21, 4.9]
    @State var oneMeterMetrics: [Int: Double] = [:]
    @State var threeMeterMetrics: [Int: Double] = [:]
    @State var platformMetrics: [Int: Double] = [:]
    @State var overallMetrics: [Int: Double] = [:]
    let diveTableData: [String: DiveData]? = getDiveTableData()
    var body: some View {
        ZStack {
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
            Polygon(metrics: metrics)
                .fill(Custom.medBlue.opacity(0.5))
                .frame(width: 500)
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
                    oneMeterMetrics = skillGraphMetrics(d: divesByCategory, height: 1)
                    threeMeterMetrics = skillGraphMetrics(d: divesByCategory, height: 3)
                    platformMetrics = skillGraphMetrics(d: divesByCategory, height: 5)
                    var divisor = 3.0
                    for i in 1..<6 {
                        var divisor = 3.0
                        if platformMetrics[i] == 0.0 {
                            divisor = 2.0
                        }
                        let total = (oneMeterMetrics[i] ?? 0.0) + (threeMeterMetrics[i] ?? 0.0) + (platformMetrics[i] ?? 0.0)
                        overallMetrics[i] = total / divisor
                    }
                    print(overallMetrics)
                }
            }
        }
        .scaleEffect(0.5)
        .rotationEffect(.degrees(-17.4))
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


//struct SkillsGraphView_Previews: PreviewProvider {
//    static var previews: some View {
//        SkillsGraph()
//    }
//}
