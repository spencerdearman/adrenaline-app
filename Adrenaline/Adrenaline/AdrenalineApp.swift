//
//  AdrenalineApp.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI
import CoreData

private struct ModelDB: EnvironmentKey {
    static var defaultValue: ModelDataController {
        get {
            ModelDataController()
        }
    }
}

struct UpcomingMeetsKey: EnvironmentKey {
    static let defaultValue: MeetDict? = nil
}

struct CurrentMeetsKey: EnvironmentKey {
    static let defaultValue: CurrentMeetList? = nil
}

struct LiveResultsKey: EnvironmentKey {
    static let defaultValue: LiveResultsDict? = nil
}

struct PastMeetsKey: EnvironmentKey {
    static let defaultValue: MeetDict? = nil
}

struct MeetsParsedCountKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

struct TotalMeetsParsedCountKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

struct IsFinishedCountingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct IsIndexingMeetsKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct GetUserKey: EnvironmentKey {
    static let defaultValue: (String) -> User? = { _ in return nil }
}

private struct AddUserKey: EnvironmentKey {
    static let defaultValue: (String, String, String, String?, String) -> () = { _, _, _, _, _ in }
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
    
    var getUser: (String) -> User? {
        get { self[GetUserKey.self] }
        set { self[GetUserKey.self] = newValue }
    }
    
    var addUser: (String, String, String, String?, String) -> () {
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
}

extension View {
    func modelDB(_ modelDB: ModelDataController) -> some View {
        environment(\.modelDB, modelDB)
    }
}

@main
struct AdrenalineApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of ModelDataController()
    @StateObject var modelDataController = ModelDataController()
    @StateObject var meetParser: MeetParser = MeetParser()
    @State var isIndexingMeets: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
                .environment(\.getUser, modelDataController.getUser)
                .environment(\.addUser, modelDataController.addUser)
                .environment(\.addAthlete, modelDataController.addAthlete)
                .environment(\.updateUserField, modelDataController.updateUserField)
                .environment(\.dropUser, modelDataController.dropUser)
                .environment(\.updateAthleteField, modelDataController.updateAthleteField)
                .environment(\.updateAthleteSkillRating, modelDataController.updateAthleteSkillRating)
                .environment(\.dictToTuple, modelDataController.dictToTuple)
                .onAppear {
                    // isIndexingMeets is set to false by default so it is only executed from start
                    //     to finish one time (allows indexing to occur in the background without
                    //     starting over)
                    if !isIndexingMeets {
                        isIndexingMeets = true
                        
                        // Runs this task asynchronously so rest of app can function while this finishes
                        Task {
                            //                        await SkillRating(diveStatistics: nil).testMetrics(0)
                            //                        await SkillRating(diveStatistics: nil).testMetrics(0, includePlatform: false)
                            //                        await SkillRating(diveStatistics: nil).testMetrics(0, onlyPlatform: true)
                            let moc = modelDataController.container.viewContext
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
                            let meets = try? moc.fetch(fetchRequest) as? [DivingMeet]
                            
                            try await meetParser.parseMeets(storedMeets: meets)
                            
                            // Check that each set of meets is not nil and add each to the database
                            if let upcoming = meetParser.upcomingMeets {
                                modelDataController.addRecords(records: modelDataController.dictToTuple(dict: upcoming), type: .upcoming)
                            }
                            if let current = meetParser.currentMeets {
                                modelDataController.addRecords(records: modelDataController.dictToTuple(dict: current), type: .current)
                            }
                            if let past = meetParser.pastMeets {
                                modelDataController.addRecords(records: modelDataController.dictToTuple(dict: past), type: .past)
                            }
                            
                            isIndexingMeets = false
                        }
                    }
                }
        }
    }
}
