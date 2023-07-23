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
