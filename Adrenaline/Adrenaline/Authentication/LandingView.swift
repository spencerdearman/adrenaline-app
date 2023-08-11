//
//  LandingView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/11/23.
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var userData: UserData
    @StateObject private var appLogic: AppLogic
    
    init() {
        let userData = UserData()
        _appLogic = StateObject(wrappedValue: AppLogic(userData: userData))
    }
    
    var body: some View {
        VStack {
            if !userData.signedIn {
                Button(action: {
                    Task {
                        do {
                            try await appLogic.authenticateWithHostedUI()
                        } catch {
                            print("Error authenticating: \(error)")
                        }
                    }
                }) {
                    Text("Sign In")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("Welcome, User!")
                    .padding()
            }
        }
        .onAppear {
        }
    }
}

