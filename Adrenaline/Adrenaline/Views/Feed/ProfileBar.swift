//
//  ProfileBar.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/26/23.
//

import SwiftUI

struct ProfileBar: View {
    private let screenWidth = UIScreen.main.bounds.width
    var title = ""
    @State var showSheet = false
    @State var showAccount = true
    @State var isLogged = true
    
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
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
                    NewSearchView()
                }
                
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                    .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
                    .cornerRadius(10)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .backgroundStyle(cornerRadius: 18, opacity: 0.4)
                    .transition(.scale.combined(with: .slide))
                }
//
//                Button {
//                    withAnimation {
//                        if isLogged {
//                            showAccount = true
//                        }
//                    }
//                } label: {
//                    Image(systemName: "gear")
//                    .frame(width: screenWidth * 0.06, height: screenWidth * 0.06)
//                    .cornerRadius(10)
//                    .padding(8)
//                    .background(.ultraThinMaterial)
//                    .backgroundStyle(cornerRadius: 18, opacity: 0.4)
//                    .transition(.scale.combined(with: .slide))
//                }
                .accessibilityElement()
                .accessibilityLabel("Account")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding()
        }
    }
}
