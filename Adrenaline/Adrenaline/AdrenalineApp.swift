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

private struct GetMaleAthletesKey: EnvironmentKey {
    static let defaultValue: () -> [Athlete]? = { return nil }
}

private struct GetFemaleAthletesKey: EnvironmentKey {
    static let defaultValue: () -> [Athlete]? = { return nil }
}

private struct GetUserKey: EnvironmentKey {
    static let defaultValue: (String) -> User? = { _ in return nil }
}

private struct GetUsersKey: EnvironmentKey {
    static let defaultValue: (String?, String?) -> [User]? = { _, _ in return nil }
}

private struct GetAthleteKey: EnvironmentKey {
    static let defaultValue: (String) -> Athlete? = { _ in return nil }
}

private struct AddUserKey: EnvironmentKey {
    static let defaultValue: (String, String, String, String?, String, String) -> () = {
        _, _, _, _, _, _ in }
}

private struct AddAthleteKey: EnvironmentKey {
    static let defaultValue: (String, String, String, String?, String) -> () = { _, _, _, _, _ in }
}

private struct UpdateUserFieldKey: EnvironmentKey {
    static let defaultValue: (String, String, Any?) -> () = { _, _, _ in }
}

private struct DropUserKey: EnvironmentKey {
    static let defaultValue: (String) -> () =  { _ in }
}

private struct UpdateAthleteFieldKey: EnvironmentKey {
    static let defaultValue: (String, String, Any?) -> () = { _, _, _ in }
}

private struct UpdateAthleteSkillRatingKey: EnvironmentKey {
    static let defaultValue: (String, Double?, Double?) -> () = { _, _, _ in }
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

private struct AddFollowedByDiveMeetsIDKey: EnvironmentKey {
    static let defaultValue: (String, String, String) -> () = { _, _, _ in }
}

private struct AddFollowedByEmailKey: EnvironmentKey {
    static let defaultValue: (String, String, String) -> () = { _, _, _ in }
}

private struct GetFollowedByDiveMeetsIDKey: EnvironmentKey {
    static let defaultValue: (String) -> Followed? = { _ in return nil }
}

private struct GetFollowedByEmailKey: EnvironmentKey {
    static let defaultValue: (String) -> Followed? = { _ in return nil }
}

private struct DropFollowedByDiveMeetsIDKey: EnvironmentKey {
    static let defaultValue: (String) -> () = { _ in }
}

private struct DropFollowedByEmailKey: EnvironmentKey {
    static let defaultValue: (String) -> () = { _ in }
}

private struct AddFollowedToUserKey: EnvironmentKey {
    static let defaultValue: (User, Followed) -> () = { _, _ in }
}

private struct DropFollowedFromUserKey: EnvironmentKey {
    static let defaultValue: (User, Followed) -> () = { _, _ in }
}

extension EnvironmentValues {
    var modelDB: ModelDataController {
        get { self[ModelDB.self] }
        set { self[ModelDB.self] = newValue }
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
    
    var getMaleAthletes: () -> [Athlete]? {
        get { self[GetMaleAthletesKey.self] }
        set { self[GetMaleAthletesKey.self] = newValue }
    }
    
    var getFemaleAthletes: () -> [Athlete]? {
        get { self[GetFemaleAthletesKey.self] }
        set { self[GetFemaleAthletesKey.self] = newValue }
    }
    
    var getUser: (String) -> User? {
        get { self[GetUserKey.self] }
        set { self[GetUserKey.self] = newValue }
    }
    
    var getUsers: (String?, String?) -> [User]? {
        get { self[GetUsersKey.self] }
        set { self[GetUsersKey.self] = newValue }
    }
    
    var getAthlete: (String) -> Athlete? {
        get { self[GetAthleteKey.self] }
        set { self[GetAthleteKey.self] = newValue }
    }
    
    var addUser: (String, String, String, String?, String, String) -> () {
        get { self[AddUserKey.self] }
        set { self[AddUserKey.self] = newValue }
    }
    
    var addAthlete: (String, String, String, String?, String) -> () {
        get { self[AddAthleteKey.self] }
        set { self[AddAthleteKey.self] = newValue }
    }
    
    var updateUserField: (String, String, Any?) -> () {
        get { self[UpdateUserFieldKey.self] }
        set { self[UpdateUserFieldKey.self] = newValue }
    }
    
    var dropUser: (String) -> () {
        get { self[DropUserKey.self] }
        set { self[DropUserKey.self] = newValue }
    }
    
    var updateAthleteField: (String, String, Any?) -> () {
        get { self[UpdateAthleteFieldKey.self] }
        set { self[UpdateAthleteFieldKey.self] = newValue }
    }
    
    var updateAthleteSkillRating: (String, Double?, Double?) -> () {
        get { self[UpdateAthleteSkillRatingKey.self] }
        set { self[UpdateAthleteSkillRatingKey.self] = newValue }
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
    
    var addFollowedByDiveMeetsID: (String, String, String) -> () {
        get { self[AddFollowedByDiveMeetsIDKey.self] }
        set { self[AddFollowedByDiveMeetsIDKey.self] = newValue }
    }
    
    var addFollowedByEmail: (String, String, String) -> () {
        get { self[AddFollowedByEmailKey.self] }
        set { self[AddFollowedByEmailKey.self] = newValue }
    }
    
    var getFollowedByDiveMeetsID: (String) -> Followed? {
        get { self[GetFollowedByDiveMeetsIDKey.self] }
        set { self[GetFollowedByDiveMeetsIDKey.self] = newValue }
    }
    
    var getFollowedByEmail: (String) -> Followed? {
        get { self[GetFollowedByEmailKey.self] }
        set { self[GetFollowedByEmailKey.self] = newValue }
    }
    
    var dropFollowedByDiveMeetsID: (String) -> () {
        get { self[DropFollowedByDiveMeetsIDKey.self] }
        set { self[DropFollowedByDiveMeetsIDKey.self] = newValue }
    }
    
    var dropFollowedByEmail: (String) -> () {
        get { self[DropFollowedByEmailKey.self] }
        set { self[DropFollowedByEmailKey.self] = newValue }
    }
    
    var addFollowedToUser: (User, Followed) -> () {
        get { self[AddFollowedToUserKey.self] }
        set { self[AddFollowedToUserKey.self] = newValue }
    }
    
    var dropFollowedFromUser: (User, Followed) -> () {
        get { self[DropFollowedFromUserKey.self] }
        set { self[DropFollowedFromUserKey.self] = newValue }
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

@main
struct AdrenalineApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of ModelDataController()
    @StateObject var modelDataController = ModelDataController()
    @StateObject var meetParser: MeetParser = MeetParser()
    @StateObject var networkMonitor: NetworkMonitor = NetworkMonitor()
    @StateObject var appLogic: AppLogic = AppLogic()
//    @StateObject var userData: UserData = UserData()
    @State var isIndexingMeets: Bool = false
//    var appLogic: AppLogic {
//        AppLogic(userData: userData)
//    }
    
    init() {
        appLogic.configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environmentObject(userData)
                .environmentObject(appLogic)
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
                .environment(\.getMaleAthletes, modelDataController.getMaleAthletes)
                .environment(\.getFemaleAthletes, modelDataController.getFemaleAthletes)
                .environment(\.getUser, modelDataController.getUser)
                .environment(\.getUsers, modelDataController.getUsers)
                .environment(\.getAthlete, modelDataController.getAthlete)
                .environment(\.addUser, modelDataController.addUser)
                .environment(\.addAthlete, modelDataController.addAthlete)
                .environment(\.updateUserField, modelDataController.updateUserField)
                .environment(\.dropUser, modelDataController.dropUser)
                .environment(\.updateAthleteField, modelDataController.updateAthleteField)
                .environment(\.updateAthleteSkillRating, modelDataController.updateAthleteSkillRating)
                .environment(\.dictToTuple, modelDataController.dictToTuple)
                .environment(\.validatePassword, modelDataController.validatePassword)
                .environment(\.networkIsConnected, networkMonitor.isConnected)
                .environment(\.networkIsCellular, networkMonitor.isCellular)
                .environment(\.addFollowedByDiveMeetsID, modelDataController.addFollowedByDiveMeetsID)
                .environment(\.addFollowedByEmail, modelDataController.addFollowedByEmail)
                .environment(\.getFollowedByDiveMeetsID, modelDataController.getFollowedByDiveMeetsID)
                .environment(\.getFollowedByEmail, modelDataController.getFollowedByEmail)
                .environment(\.dropFollowedByDiveMeetsID, modelDataController.dropFollowedByDiveMeetsID)
                .environment(\.dropFollowedByEmail, modelDataController.dropFollowedByEmail)
                .environment(\.addFollowedToUser, modelDataController.addFollowedToUser)
                .environment(\.dropFollowedFromUser, modelDataController.dropFollowedFromUser)
                .onAppear {
                    networkMonitor.start()
                    
                    // isIndexingMeets is set to false by default so it is only executed from start
                    //     to finish one time (allows indexing to occur in the background without
                    //     starting over)
                    if !isIndexingMeets {
                        isIndexingMeets = true
                        
                        // Runs this task asynchronously so rest of app can function while this
                        // finishes
                        Task {
                            // await SkillRating(diveStatistics: nil).testMetrics(0)
                            // await SkillRating(diveStatistics: nil)
                            //     .testMetrics(0, includePlatform: false)
                            // await SkillRating(diveStatistics: nil)
                            //     .testMetrics(0, onlyPlatform: true)
                            let moc = modelDataController.container.viewContext
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                                entityName: "DivingMeet")
                            let meets = try? moc.fetch(fetchRequest) as? [DivingMeet]
                            
                            try await meetParser.parseMeets(storedMeets: meets)
                            
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
