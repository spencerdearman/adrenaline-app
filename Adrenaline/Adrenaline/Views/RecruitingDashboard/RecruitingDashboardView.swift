//
//  RecruitingDashboardView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/7/24.
//

import SwiftUI

struct RecruitingDashboardView: View {
    @State private var contentHasScrolled: Bool = false
    @State private var feedModel: FeedModel = FeedModel()
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        VStack {
            Text("")
        }
        .overlay {
            NavigationBar(title: "Recruiting",
                          showPlus: false,
                          showSearch: true,
                          newUser: $newUser,
                          showAccount: $showAccount,
                          contentHasScrolled: $contentHasScrolled,
                          feedModel: $feedModel, 
                          recentSearches: $recentSearches,
                          uploadingPost: $uploadingPost)
            .frame(width: screenWidth)
        }
    }
}
