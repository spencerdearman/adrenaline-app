//
//  RankingsView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/24/23.
//

import SwiftUI

enum RankingType: String, CaseIterable {
    case springboard = "Springboard"
    case combined = "Combined"
    case platform = "Platform"
}

enum GenderInt: Int, CaseIterable {
    case male = 0
    case female = 1
}

struct RankingsView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.modelDB) var db
    @State private var rankingType: RankingType = .combined
    @State private var gender: Gender = .male
    @Namespace var namespace
    
    var body: some View {
        VStack {
            Text("Rankings")
                .font(.title)
                .bold()
            
            BubbleSelectView(selection: $rankingType)
                .padding([.leading, .trailing])
            
            VStack {
                HStack {
                    Spacer()
//                    Text("Male")
//                        .font(.title2)
//                        .bold(gender == .male)
//                        .foregroundColor(gender == .male ? .primary : .secondary)
//                        .onTapGesture {
//                            if gender == .female {
//                                gender = .male
//                            }
//                        }
                    MaleView(selected: $gender, namespace: namespace)
                    Spacer()
                    FemaleView(selected: $gender, namespace: namespace)
//                    Text("Female")
//                        .font(.title2)
//                        .bold(gender == .female)
//                        .foregroundColor(gender == .female ? .primary : .secondary)
//                        .onTapGesture {
//                            if gender == .male {
//                                gender = .female
//                            }
//                        }
                    Spacer()
                }
            }
            
            Spacer()
            
        }
    }
}

struct MaleView: View {
    @Binding var selected: Gender
    var namespace: Namespace.ID
    
    var body: some View {
        (
            selected == .male
            ? VStack {
                Text("Male")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Rectangle()
                    .foregroundColor(.primary)
                    .frame(height: 5)
            }
                .matchedGeometryEffect(id: "switch", in: namespace)
            :
                VStack {
                    Text("Male")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.secondary)
                    Rectangle()
                        .foregroundColor(.primary)
                        .frame(height: 0)
                }
                .matchedGeometryEffect(id: "switch", in: namespace)
        )
        .onTapGesture {
            if selected == .female {
                selected = .male
            }
        }
    }
}

struct FemaleView: View {
    @Binding var selected: Gender
    var namespace: Namespace.ID
    
    var body: some View {
        (
            selected == .female
            ? VStack {
                Text("Female")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                Rectangle()
                    .foregroundColor(.primary)
                    .frame(height: 5)
            }
                .matchedGeometryEffect(id: "switch", in: namespace)
            :
                VStack {
                    Text("Female")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.secondary)
                    Rectangle()
                        .foregroundColor(.primary)
                        .frame(height: 0)
                }
                .matchedGeometryEffect(id: "switch", in: namespace)
        )
        .onTapGesture {
            if selected == .male {
                selected = .female
            }
        }
    }
}

struct RankingsView_Previews: PreviewProvider {
    static var previews: some View {
        RankingsView()
    }
}
