//
//  LandingView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/11/23.
//

import SwiftUI

struct SignOutButton : View {
//    @EnvironmentObject var userData: UserData
    @EnvironmentObject var appLogic: AppLogic
    
    var body: some View {
        NavigationLink(destination: LandingView()) {
            Button(action: {
                Task {
                    do {
                        try await appLogic.signOut()
                        // Reset user data after signing out
                        appLogic.isSignedIn = false
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
//    @EnvironmentObject var user: UserData
    @EnvironmentObject var appLogic: AppLogic
    
    func delay(seconds: Double, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
    }
    
    var body: some View {
        VStack {
            if !appLogic.isSignedIn {
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
                SignOutButton()
                    .onAppear{
                        print("Coming into the signout portion")
                    }
            }
        }
        .onChange(of: appLogic.isSignedIn, perform: { _ in
            print(appLogic.isSignedIn)})
        .onAppear {
//            user.signedIn = true
//            print(user.signedIn)
//            delay(seconds: 5) {
//                print(appLogic.signedIn)
//            }
            Task {
                try await appLogic.signOut()
            }
        }
    }
}

