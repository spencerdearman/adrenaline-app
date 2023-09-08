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
    @Binding var showAccount: Bool
    @Binding var email: String
    @Binding var graphUser: GraphUser?
    @Binding var newAthlete: NewAthlete?
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var title = ""
    @State var showSheet = false
    @State var isLogged = true
    
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
                    NewSearchView()
                }
                
                NavigationLink {
                    SettingsView(state: state, email: $email, graphUser: $graphUser, newAthlete: $newAthlete)
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
