//
//  UserData.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/10/23.
//

import SwiftUI
import Combine
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin


class UserData: ObservableObject {
    @Published var signedIn: Bool = false
}

class AppLogic: ObservableObject {
    @Published var isSignedIn: Bool = false
    var userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
        configureAmplify()
    }
    
    func configureAmplify() {
        do {
            // reduce verbosity of AWS SDK
            SDKLoggingSystem.initialize(logLevel: .warning)
            //Amplify.Logging.logLevel = .info
            
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            
            try Amplify.configure()
            print("Amplify initialized")
            
            // asynchronously
            Task {
                
                // check if user is already signed in from a previous run
                let session = try await Amplify.Auth.fetchAuthSession()
                
                // and update the GUI accordingly
                await self.updateUI(forSignInStatus: session.isSignedIn)
            }
            
            // listen to auth events.
            // see https://github.com/aws-amplify/amplify-ios/blob/dev-preview/Amplify/Categories/Auth/Models/AuthEventName.swift
            let _  = Amplify.Hub.listen(to: .auth) { payload in
                switch payload.eventName {
                    
                case HubPayload.EventName.Auth.signedIn:
                    
                    Task {
                        print("==HUB== User signed In, update UI")
                        await self.updateUI(forSignInStatus: true)
                    }
                    
                    // if you want to get user attributes
                    Task {
                        let authUserAttributes = try? await Amplify.Auth.fetchUserAttributes()
                        if let authUserAttributes {
                            print("User attribtues - \(authUserAttributes)")
                        } else {
                            print("Failed fetching user attributes failed")
                        }
                    }
                    
                case HubPayload.EventName.Auth.signedOut:
                    Task {
                        print("==HUB== User signed Out, update UI")
                        await self.updateUI(forSignInStatus: false)
                    }
                    
                case HubPayload.EventName.Auth.sessionExpired:
                    Task {
                        print("==HUB== Session expired, show sign in aui")
                        await self.updateUI(forSignInStatus: false)
                    }
                    
                default:
                    //print("==HUB== \(payload)")
                    break
                }
            }
        } catch let error as AuthError {
            print("Authentication error: \(error)")
        } catch {
            print("Error when configuring Amplify: \(error)")
        }
    }
    
    // Other functions for authentication, sign in, sign out, etc.
    
    // change our internal state, this triggers an UI update on the main thread
    @MainActor
    func updateUI(forSignInStatus: Bool) async {
        self.userData.signedIn = forSignInStatus
    }
    
    // Sign in with Cognito web user interface
    public func authenticateWithHostedUI() async throws {
        print("hostedUI()")
        
        // Find the key window to use as presentation anchor
        guard let keyWindow = findKeyWindow() else {
            throw AuthenticationError.keyWindowNotFound
        }
        
        do {
            let result = try await Amplify.Auth.signInWithWebUI(presentationAnchor: keyWindow)
            if result.isSignedIn {
                print("Sign in succeeded")
            } else {
                print("Signin failed or required a next step")
            }
        } catch {
            print("Error signing in: \(error)")
        }
    }
    
    // Find the key window from connected scenes
    private func findKeyWindow() -> UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }
        return nil
    }
    
    enum AuthenticationError: Error {
        case keyWindowNotFound
    }
    
    
    // signout globally
    public func signOut() async throws {
        
        // https://docs.amplify.aws/lib/auth/signOut/q/platform/ios
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        let _ = await Amplify.Auth.signOut(options: options)
        print("Signed Out")
    }
}
