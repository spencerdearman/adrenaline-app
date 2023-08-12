//
//  LandingView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/11/23.
//

import SwiftUI
import Combine
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin

struct SignOutButton : View {
    @Binding var authenticated: Bool
    @EnvironmentObject var appLogic: AppLogic
    
    var body: some View {
        NavigationLink(destination: LandingView()) {
            Button(action: {
                Task {
                    do {
                        try await appLogic.signOut()
                        authenticated = false
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
    @EnvironmentObject var appLogic: AppLogic
    @State private var authenticated: Bool = false
    
    func delay(seconds: Double, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !authenticated {
                    Button(action: {
                        Task {
                            do {
                                try await appLogic.authenticateWithHostedUI()
                                let session = try await Amplify.Auth.fetchAuthSession()
                                if session.isSignedIn {
                                    authenticated = true
                                }
                            } catch {
                                print("Error authenticating: \(error)")
                            }
                        }
                    }) {
                        UserBadge()
                    }
                } else {
                    SignOutButton(authenticated: $authenticated)
                        .onAppear{
                            print("Coming into the signout portion")
                        }
                }
            }
        }
        .onAppear {
            Task {
                let session = try await Amplify.Auth.fetchAuthSession()
                if session.isSignedIn {
                    authenticated = true
                }
            }
        }
    }
}

