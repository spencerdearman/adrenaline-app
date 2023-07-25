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
    
    var body: some View {
        VStack {
            Text("Rankings")
                .font(.title)
                .bold()
            
            BubbleSelectView(selection: $rankingType)
                .padding([.leading, .trailing])
            
            BubbleSelectView(selection: $gender)
                .padding([.leading, .trailing])
            
            Divider()
            
            RankingListView()
            
            Spacer()
        }
    }
}

struct RankingListView: View {
    var body: some View {
        Text("")
    }
}

struct RankingsView_Previews: PreviewProvider {
    static var previews: some View {
        RankingsView()
    }
}
