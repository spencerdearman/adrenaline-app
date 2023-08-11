//
//  LandingView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/11/23.
//

import SwiftUI

struct SignOutButton : View {
    @EnvironmentObject var userData: UserData
    @StateObject private var appLogic: AppLogic
    
    var body: some View {
        NavigationLink(destination: LandingView(user: userData)) {
            Button(action: {
                Task {
                    do {
                        try await appLogic.signOut()
                        // Reset user data after signing out
                        userData.signedIn = false
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }) {
                Text("Sign Out")
            }
        }
    }
}

struct LandingView: View {
    @ObservedObject public var user : UserData
//    @EnvironmentObject var userData: UserData
    @StateObject private var appLogic: AppLogic
//
    init(user: UserData) {
        self.user = user
        _appLogic = StateObject(wrappedValue: AppLogic(userData: user))
    }
    
    var body: some View {
        VStack {
            if !user.signedIn {
                Button(action: {
                    Task {
                        do {
                            try await appLogic.authenticateWithHostedUI()
                        } catch {
                            print("Error authenticating: \(error)")
                        }
                    }
                }) {
                    //This is where the 'Sign in Button' or content goes
                    UserBadge()
                }
            } else {
                Home().environmentObject(user)
            }
        }
        .onAppear {
        }
    }
}

