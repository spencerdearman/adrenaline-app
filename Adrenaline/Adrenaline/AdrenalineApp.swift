//
//  AdrenalineApp.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI
import CoreData
import Combine
import ClientRuntime
import Amplify
import AWSCognitoAuthPlugin

private struct AuthenticatedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct NetworkIsConnectedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct NetworkIsCellularKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct NewUsersKey: EnvironmentKey {
    static let defaultValue: [NewUser] = []
}

private struct NewMeetsKey: EnvironmentKey {
    static let defaultValue: [NewMeet] = []
}

private struct NewTeamsKey: EnvironmentKey {
    static let defaultValue: [NewTeam] = []
}

private struct CollegesKey: EnvironmentKey {
    static let defaultValue: [College] = []
}

extension EnvironmentValues {
    var authenticated: Bool {
        get { self[AuthenticatedKey.self] }
        set { self[AuthenticatedKey.self] = newValue }
    }
    
    var networkIsConnected: Bool {
        get { self[NetworkIsConnectedKey.self] }
        set { self[NetworkIsConnectedKey.self] = newValue }
    }
    
    var networkIsCellular: Bool {
        get { self[NetworkIsCellularKey.self] }
        set { self[NetworkIsCellularKey.self] = newValue }
    }
    
    var newUsers: [NewUser] {
        get { self[NewUsersKey.self] }
        set { self[NewUsersKey.self] = newValue }
    }
    
    var newMeets: [NewMeet] {
        get { self[NewMeetsKey.self] }
        set { self[NewMeetsKey.self] = newValue }
    }
    
    var newTeams: [NewTeam] {
        get { self[NewTeamsKey.self] }
        set { self[NewTeamsKey.self] = newValue }
    }
    
    var colleges: [College] {
        get { self[CollegesKey.self] }
        set { self[CollegesKey.self] = newValue }
    }
}

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

let CLOUDFRONT_STREAM_BASE_URL = "https://d3mgzcs3lrwvom.cloudfront.net/"
let CLOUDFRONT_IMAGE_BASE_URL = "https://dc666cmbq88s6.cloudfront.net/"
let MAIN_BUCKET = "adrenalinexxxxx153503-main"
let STREAMS_BUCKET = "adrenaline-main-video-streams"

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            do {
                try await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
                let apnsToken = deviceToken.map { String(format: "%02x", $0) }.joined()
                UserDefaults.standard.set(apnsToken, forKey: "userToken")
                print(apnsToken)
                print("Registered with Pinpoint.")
            } catch {
                print("Error registering with Pinpoint: \(error)")
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        
        do {
            try await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
        } catch {
            print("Error recording receipt of notification: \(error)")
        }
        
        return .newData
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // ...
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when a user opens (taps or clicks) a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        do {
            try await Amplify.Notifications.Push.recordNotificationOpened(response)
        } catch {
            print("Error recording notification opened: \(error)")
        }
    }
}

@main
struct AdrenalineApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of ModelDataController()
    @StateObject var networkMonitor: NetworkMonitor = NetworkMonitor()
    @StateObject var appLogic = AppLogic()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appLogic)
                .environment(\.authenticated, appLogic.isSignedIn)
                .environment(\.newUsers, appLogic.users)
                .environment(\.newMeets, appLogic.meets)
                .environment(\.newTeams, appLogic.teams)
                .environment(\.colleges, appLogic.colleges)
                .environment(\.networkIsConnected, networkMonitor.isConnected)
                .environment(\.networkIsCellular, networkMonitor.isCellular)
                .onChange(of: appLogic.dataStoreReady) {
                    print(appLogic.dataStoreReady
                          ? "DataStore ready"
                          : "DataStore not ready")
                }
                .onAppear {
                    appLogic.configureAmplify()
                    networkMonitor.start()
                    Task {
                        let user = try await Amplify.Auth.getCurrentUser().userId
                        try await Amplify.Notifications.Push.identifyUser(userId: user)
                    }                }
        }
    }
}
