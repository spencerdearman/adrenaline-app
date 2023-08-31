//
//  OldAdrenalineProfile.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/30/23.
//

import SwiftUI

struct OldAdrenalineProfileView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.getUser) private var getUser
    @Environment(\.getAthlete) private var getAthlete
    var firstSignIn: Bool = false
    var showBackButton: Bool = false
    var userEmail: String
    @State private var offset: CGFloat = 0
    @State var user: User?
    @State var userViewData: UserViewData = UserViewData()
    @Binding var loginSuccessful: Bool
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    func formatLocationString(_ input: String) -> String {
        var formattedString = input
        
        if let spaceIndex = input.lastIndex(of: " ") {
            formattedString.insert(",", at: spaceIndex)
        }
        if formattedString.count >= 2 {
            let lastTwo = formattedString.suffix(2).uppercased()
            formattedString.replaceSubrange(
                formattedString.index(formattedString.endIndex,
                                      offsetBy: -2)..<formattedString.endIndex, with: lastTwo)
        }
        return formattedString
    }
    
    var body: some View {
        ZStack {
            (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
            Image(currentMode == .light ? "ProfileBackground-Light" : "ProfileBackground-Dark")
                .frame(height: screenHeight * 0.7)
                .offset(x: screenWidth * 0.2, y: -screenHeight * 0.4)
                .scaleEffect(0.7)
            Text("OLD PROFILE")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if showBackButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        NavigationViewBackButton()
                    }
                }
            }
        }
    }
}
