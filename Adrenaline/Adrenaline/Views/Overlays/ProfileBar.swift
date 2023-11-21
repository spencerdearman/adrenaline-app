//
//  ProfileBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/26/23.
//

import SwiftUI
import Authenticator

struct ProfileBar: View {
    @ObservedObject var state: SignedInState
    @State private var newAthlete: NewAthlete? = nil
    @State private var showSheet = false
    @State private var isLogged = true
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var updateDataStoreData: Bool
    
    var user: NewUser?
    var title = ""
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                Button {
                    withAnimation(.closeCard) {
                        showAccount = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                }
                .offset(x: -screenWidth * 0.57)
                
                Button {
                    showSheet.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                }
                .sheet(isPresented: $showSheet) {
                    NewSearchView(recentSearches: $recentSearches)
                }
                
                NavigationLink {
                    SettingsView(state: state, newUser: user, showAccount: $showAccount,
                                 updateDataStoreData: $updateDataStoreData)
                } label: {
                    Image(systemName: "gear")
                        .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                        .cornerRadius(10)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                        .transition(.scale.combined(with: .slide))
                }
                .accessibilityElement()
                .accessibilityLabel("Account")
            }
            .frame(maxWidth: .infinity, maxHeight: screenHeight, alignment: .topTrailing)
            .padding()
        }
    }
}
