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
import AWSDataStorePlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

//Creating App Logic Structure for Authentication
class AppLogic: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var users: [GraphUser] = []
    var imageStore: ImageStore = ImageStore()
    
    func configureAmplify() {
        do {
            // reduce verbosity of AWS SDK
            SDKLoggingSystem.initialize(logLevel: .warning)
            Amplify.Logging.logLevel = .info
            
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            //Initializing Amplify
            try Amplify.configure()
            print("Amplify initialized")
            
            // asynchronously
            Task {
                // check if user is already signed in from a previous run
                let session = try await Amplify.Auth.fetchAuthSession()
                
                // and update the GUI accordingly
                await self.updateUI(forSignInStatus: session.isSignedIn)
                print("Updating GUI")
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
//                    print("==HUB== \(payload)")
                    break
                }
            }
        } catch let error as AuthError {
            print("Authentication error: \(error)")
        } catch {
            print("Error when configuring Amplify: \(error)")
        }
        
    }
//}
//
//extension AppLogic {
    // Other functions for authentication, sign in, sign out, etc.
    
    // Changing the internal state, this triggers an UI update on the main thread
    @MainActor
    func updateUI(forSignInStatus: Bool) async {
        self.isSignedIn = forSignInStatus
        print("Changing signed in Status: " + String(self.isSignedIn))
        
        // load landmarks at start of app when user signed in
        if (forSignInStatus && self.users.isEmpty) {
            self.users = await self.queryUsers()
        } else {
            self.users = []
        }
    }
    
    // Sign in with Cognito web user interface
    @MainActor
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
    @MainActor
    private func findKeyWindow() -> UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }
        return nil
    }
    
    func queryUsers() async -> [GraphUser] {
        print("Query users")
        
        do {
            let queryResult = try await Amplify.API.query(request: .list(NewUser.self))
            print("Successfully retrieved list of users")
            
            // convert [ LandmarkData ] to [ LandMark ]
            let result = try queryResult.get().map { newUser in
                GraphUser.init(from: newUser)
            }
            
            return result
            
        } catch let error as APIError {
            print("Failed to load data from api : \(error)")
        } catch {
            print("Unexpected error while calling API : \(error)")
        }
        
        return []
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

struct GraphUser: Hashable, Codable, Identifiable {
    let id: Int
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var diveMeetsID: String?
    var accountType: String
    var followed: [String]
    var createdAt: String?
    var updatedAt: String?
    var athleteId: String?
    var coachId: String?
}


// Added later, not generated code
extension GraphUser {
    // construct from API Data
    init(from : NewUser)  {
        
        guard let i = Int(from.id) else {
            preconditionFailure("Can not create user, Invalid ID : \(from.id) (expected Int)")
        }
        
        // assume all fields are non null.
        // real life project must spend more time thinking about null values and
        // maybe convert the above code (original Landmark class) to optionals
        // I am not doing it for this workshop as this would imply too many changes in UI code
        // MARK: - TODO
        
        id = i
        firstName = from.firstName
        lastName = from.lastName
        email = from.email
        phone = from.phone
        diveMeetsID = from.diveMeetsID
        accountType = from.accountType
        // TODO: fix this later
        followed = []
        createdAt = from.createdAt?.iso8601String
        updatedAt = from.updatedAt?.iso8601String
        athleteId = from.newUserAthleteId
        coachId = from.newUserCoachId
    }
}
