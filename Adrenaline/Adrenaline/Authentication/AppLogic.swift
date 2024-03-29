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
import AWSPinpointPushNotificationsPlugin
import AWSPinpointAnalyticsPlugin

//Creating App Logic Structure for Authentication
class AppLogic: ObservableObject {
    @AppStorage("authUserId") private var authUserId: String = ""
    @Published var isSignedIn: Bool = false
    @Published var initialized: Bool = false
    @Published var users: [NewUser] = []
    @Published var coaches: [CoachUser] = []
    @Published var meets: [NewMeet] = []
    @Published var teams: [NewTeam] = []
    @Published var colleges: [College] = []
    @Published var dataStoreReady: Bool = false
    @Published var currentUser: NewUser? = nil
    @Published var currentUserUpdated: Bool = false
    @Published var deepLink: URL? = nil
    
    func configureAmplify() {
        do {
            // reduce verbosity of AWS SDK
            Task {
                await SDKLoggingSystem.initialize(logLevel: .warning)
            }
            Amplify.Logging.logLevel = .info
            
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPinpointPushNotificationsPlugin(options: [.badge, .alert, .sound]))
            try Amplify.add(plugin:
                AWSPinpointAnalyticsPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            // When DataStore send a "ready" event, all syncing should be finished and all data
            // should be available
            let _ = Amplify.Hub.listen(to: .dataStore) { event in
                DispatchQueue.main.sync {
//                    print(event.eventName)
                    switch event.eventName {
                        case HubPayload.EventName.DataStore.ready:
                            // Sets boolean to true when ready event is received
                            self.dataStoreReady = true
                            break
                        case HubPayload.EventName.DataStore.outboxStatus:
                            // If outbox status event is received and it is empty, then no other
                            // events are remaining to upload to the cloud, so it is ready
                            if let data = event.data as? OutboxStatusEvent,
                               data.isEmpty {
                                self.dataStoreReady = true
                            }
                            break
                        case HubPayload.EventName.DataStore.syncReceived,
                             HubPayload.EventName.DataStore.syncQueriesReady:
                            // Ignore these events since sometimes they arrive after outbox status,
                            // which indicates completion
                            break
                        default:
                            // If other events are received, assume not ready
                            self.dataStoreReady = false
                            break
                    }
                }
            }
            
            //Initializing Amplify
            try Amplify.configure()
            print("Amplify initialized")
            initialized = true
            
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
                        
                    case HubPayload.EventName.Auth.userDeleted:
                        Task {
                            print("==HUB== User account deleted, update UI")
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
    
    @MainActor
    func observeSearchData() async {
        // load data at start of app when user signed in
        observeUsers()
        observeCoaches()
        observeMeets()
        observeTeams()
        observeColleges()
    }
    
    // Changing the internal state, this triggers an UI update on the main thread
    @MainActor
    func updateUI(forSignInStatus: Bool) async {
        self.isSignedIn = forSignInStatus
        print("Changing signed in Status: " + String(self.isSignedIn))
        
        // Skip data load if user is not signed in
        if !forSignInStatus {
            return
        }
        
        await observeSearchData()
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

extension AppLogic {
    func observeUsers() {
        let userSubscription = Amplify.DataStore.observeQuery(for: NewUser.self)

        Task {
            do {
                for try await snapshot in userSubscription {
                    await MainActor.run {
                        self.users = snapshot.items.filter { $0.accountType != "Spectator" }
                        let currentUsers = snapshot.items.filter { $0.id == authUserId }
                        if currentUsers.count == 1 {
                            self.currentUser = currentUsers[0]
                        } else {
                            self.currentUser = nil
                        }
                        currentUserUpdated = true
                        print("updated users")
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    func observeCoaches() {
        let coachSubscription = Amplify.DataStore.observeQuery(for: CoachUser.self)
        
        Task {
            do {
                for try await snapshot in coachSubscription {
                    await MainActor.run {
                        self.coaches = snapshot.items
                        print("updated coaches")
                        self.currentUserUpdated = true
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    func observeMeets() {
        let meetSubscription = Amplify.DataStore.observeQuery(for: NewMeet.self)
        
        Task {
            do {
                for try await snapshot in meetSubscription {
                    await MainActor.run {
                        self.meets = snapshot.items
                        print("updated meets")
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    func observeTeams() {
        let teamSubscription = Amplify.DataStore.observeQuery(for: NewTeam.self)
        
        Task {
            do {
                for try await snapshot in teamSubscription {
                    await MainActor.run {
                        self.teams = snapshot.items
                        print("updated teams")
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    func observeColleges() {
        let collegeSubscription = Amplify.DataStore.observeQuery(for: College.self)
        
        Task {
            do {
                for try await snapshot in collegeSubscription {
                    var colleges: [College] = []
                    for item in snapshot.items {
                        if try await item.coach == nil,
                           let coachID = item.coachID {
                            var newItem = item
                            newItem.setCoach(try await queryAWSCoachById(id: coachID))
                            newItem = try await saveToDataStore(object: newItem)
                            colleges.append(newItem)
                        } else {
                            colleges.append(item)
                        }
                    }
                    
                    await MainActor.run { [colleges] in
                        self.colleges = colleges
                        print("updated colleges")
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
}
