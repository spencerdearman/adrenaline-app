//
//  SkillsGraph.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/19/23.
//


import SwiftUI

struct SkillsGraph: View {
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
            Polygon(metrics: [4.0, 4.6, 3.56, 3.21, 4.9])
                .fill(Custom.medBlue.opacity(0.5))
                .frame(width: 500)
        }
        .scaleEffect(0.5)
        .rotationEffect(.degrees(-17.4))
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


struct SkillsGraphView_Previews: PreviewProvider {
    static var previews: some View {
        SkillsGraph()
    }
}
