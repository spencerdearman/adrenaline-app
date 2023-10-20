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

private struct ModelDB: EnvironmentKey {
    static var defaultValue: ModelDataController {
        get {
            ModelDataController()
        }
    }
}

private struct AuthenticatedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct UpcomingMeetsKey: EnvironmentKey {
    static let defaultValue: MeetDict? = nil
}

private struct CurrentMeetsKey: EnvironmentKey {
    static let defaultValue: CurrentMeetList? = nil
}

private struct LiveResultsKey: EnvironmentKey {
    static let defaultValue: LiveResultsDict? = nil
}

private struct PastMeetsKey: EnvironmentKey {
    static let defaultValue: MeetDict? = nil
}

private struct MeetsParsedCountKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

private struct TotalMeetsParsedCountKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

private struct IsFinishedCountingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct IsIndexingMeetsKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct DictToTupleKey: EnvironmentKey {
    static let defaultValue: (MeetDict) -> [MeetRecord] = { _ in [] }
}

private struct ValidatePasswordKey: EnvironmentKey {
    static let defaultValue: (String, String) -> Bool = { _, _ in return false }
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
    var modelDB: ModelDataController {
        get { self[ModelDB.self] }
        set { self[ModelDB.self] = newValue }
    }
    
    var authenticated: Bool {
        get { self[AuthenticatedKey.self] }
        set { self[AuthenticatedKey.self] = newValue }
    }
    
    var upcomingMeets: MeetDict? {
        get { self[UpcomingMeetsKey.self] }
        set { self[UpcomingMeetsKey.self] = newValue }
    }
    
    var currentMeets: CurrentMeetList? {
        get { self[CurrentMeetsKey.self] }
        set { self[CurrentMeetsKey.self] = newValue }
    }
    
    var liveResults: LiveResultsDict? {
        get { self[LiveResultsKey.self] }
        set { self[LiveResultsKey.self] = newValue }
    }
    
    var pastMeets: MeetDict? {
        get { self[PastMeetsKey.self] }
        set { self[PastMeetsKey.self] = newValue }
    }
    
    var meetsParsedCount: Int {
        get { self[MeetsParsedCountKey.self] }
        set { self[MeetsParsedCountKey.self] = newValue }
    }
    
    var totalMeetsParsedCount: Int {
        get { self[TotalMeetsParsedCountKey.self] }
        set { self[TotalMeetsParsedCountKey.self] = newValue }
    }
    
    var isFinishedCounting: Bool {
        get { self[IsFinishedCountingKey.self] }
        set { self[IsFinishedCountingKey.self] = newValue }
    }
    
    var isIndexingMeets: Bool {
        get { self[IsIndexingMeetsKey.self] }
        set { self[IsIndexingMeetsKey.self] = newValue }
    }
    
    var dictToTuple: (MeetDict) -> [MeetRecord] {
        get { self[DictToTupleKey.self] }
        set { self[DictToTupleKey.self] = newValue }
    }
    
    var validatePassword: (String, String) -> Bool {
        get { self[ValidatePasswordKey.self] }
        set { self[ValidatePasswordKey.self] = newValue }
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

extension View {
    func modelDB(_ modelDB: ModelDataController) -> some View {
        environment(\.modelDB, modelDB)
    }
}

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

<<<<<<< HEAD
let CLOUDFRONT_STREAM_BASE_URL = "https://d3mgzcs3lrwvom.cloudfront.net/"
let CLOUDFRONT_IMAGE_BASE_URL = "https://dc666cmbq88s6.cloudfront.net/"
let MAIN_BUCKET = "adrenalinexxxxx153503-main"
let STREAMS_BUCKET = "adrenaline-main-video-streams"

=======
>>>>>>> ffd7ed9 (Finished initial setup for AWS Notifications and APNs.)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            do {
                try await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
                let apnsToken = deviceToken.map { String(format: "%02x", $0) }.joined()
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
<<<<<<< HEAD
    
=======

>>>>>>> ffd7ed9 (Finished initial setup for AWS Notifications and APNs.)
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
    @StateObject var modelDataController = ModelDataController()
    @StateObject var meetParser: MeetParser = MeetParser()
    @StateObject var networkMonitor: NetworkMonitor = NetworkMonitor()
    @StateObject var appLogic = AppLogic()
    @State var isIndexingMeets: Bool = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
<<<<<<< HEAD
    
=======

>>>>>>> ffd7ed9 (Finished initial setup for AWS Notifications and APNs.)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appLogic)
                .environment(\.authenticated, appLogic.isSignedIn)
                .environment(\.newUsers, appLogic.users)
                .environment(\.newMeets, appLogic.meets)
                .environment(\.newTeams, appLogic.teams)
                .environment(\.colleges, appLogic.colleges)
                .environment(\.managedObjectContext, modelDataController.container.viewContext)
                .environment(\.modelDB, modelDataController)
                .environmentObject(meetParser)
                .environment(\.upcomingMeets, meetParser.upcomingMeets)
                .environment(\.currentMeets, meetParser.currentMeets)
                .environment(\.liveResults, meetParser.liveResults)
                .environment(\.pastMeets, meetParser.pastMeets)
                .environment(\.meetsParsedCount, meetParser.meetsParsedCount)
                .environment(\.totalMeetsParsedCount, meetParser.totalMeetsParsedCount)
                .environment(\.isFinishedCounting, meetParser.isFinishedCounting)
                .environment(\.isIndexingMeets, isIndexingMeets)
                .environment(\.dictToTuple, modelDataController.dictToTuple)
                .environment(\.validatePassword, modelDataController.validatePassword)
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
                    }
                    
                    
                
                    // isIndexingMeets is set to false by default so it is only executed from start
                    //     to finish one time (allows indexing to occur in the background without
                    //     starting over)
                    if !isIndexingMeets {
                        isIndexingMeets = true
                        // Runs this task asynchronously so rest of app can function while this
                        // finishes
                        Task {
<<<<<<< HEAD
=======
                            let moc = modelDataController.container.viewContext
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                                entityName: "DivingMeet")
                            let meets = try? moc.fetch(fetchRequest) as? [DivingMeet]
                            
//                            try await meetParser.parseMeets(storedMeets: meets)
                            
>>>>>>> ffd7ed9 (Finished initial setup for AWS Notifications and APNs.)
                            // Check that each set of meets is not nil and add each to the database
                            if let upcoming = meetParser.upcomingMeets {
                                modelDataController.addRecords(
                                    records: modelDataController.dictToTuple(dict: upcoming),
                                    type: .upcoming)
                            }
                            if let current = meetParser.currentMeets {
                                modelDataController.addRecords(
                                    records: modelDataController.dictToTuple(dict: current),
                                    type: .current)
                            }
                            if let past = meetParser.pastMeets {
                                modelDataController.addRecords(
                                    records: modelDataController.dictToTuple(dict: past),
                                    type: .past)
                            }
                            
                            await MainActor.run {
                                isIndexingMeets = false
                            }
                        }
                    }
                }
        }
    }
}
