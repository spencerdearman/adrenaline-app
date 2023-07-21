//
//  AdrenalineApp.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI
import CoreData

//private struct MeetsDB: EnvironmentKey {
//    static var defaultValue: MeetsDataController {
//        get {
//            MeetsDataController()
//        }
//    }
//}

//private struct UsersDB: EnvironmentKey {
//    static var defaultValue: UsersDataController {
//        get {
//            UsersDataController()
//        }
//    }
//}

private struct ModelDB: EnvironmentKey {
    static var defaultValue: ModelDataController {
        get {
            ModelDataController()
        }
    }
}

//private struct UsersManagedObjectContext: EnvironmentKey {
//    static var defaultValue: NSManagedObjectContext {
//        get {
//            NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        }
//    }
//}

extension EnvironmentValues {
//    var meetsDB: MeetsDataController {
//        get { self[MeetsDB.self] }
//        set { self[MeetsDB.self] = newValue }
//    }
    
//    var usersDB: UsersDataController {
//        get { self[UsersDB.self] }
//        set { self[UsersDB.self] = newValue }
//    }

    var modelDB: ModelDataController {
        get { self[ModelDB.self] }
        set { self[ModelDB.self] = newValue }
    }
    
//    var usersManagedObjectContext: NSManagedObjectContext {
//        get { self[UsersManagedObjectContext.self] }
//        set { self[UsersManagedObjectContext.self]  = newValue }
//    }
}

extension View {
//    func meetsDB(_ meetsDB: MeetsDataController) -> some View {
//        environment(\.meetsDB, meetsDB)
//    }
    
//    func usersDB(_ usersDB: UsersDataController) -> some View {
//        environment(\.usersDB, usersDB)
//    }

    func modelDB(_ modelDB: ModelDataController) -> some View {
        environment(\.modelDB, modelDB)
    }
    
//    func usersManagedObjectContext(_ usersManagedObjectContext: NSManagedObjectContext) -> some View {
//        environment(\.usersManagedObjectContext, usersManagedObjectContext)
//    }
}

//let container = NSPersistentContainer(name: "Model")

@main
struct AdrenalineApp: App {
    // Only one of these should exist, add @Environment to use variable in views
    // instead of creating a new instance of MeetsDataController()
    
//    @StateObject var meetsDataController = MeetsDataController()
//    @StateObject var usersDataController = UsersDataController()
    @StateObject var modelDataController = ModelDataController()
    @StateObject var meetParser: MeetParser = MeetParser()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, modelDataController.container.viewContext)
//                .environment(\.usersManagedObjectContext, usersDataController.container.viewContext)
//                .environment(\.meetsDB, meetsDataController)
//                .environment(\.usersDB, usersDataController)
                .environment(\.modelDB, modelDataController)
                .environmentObject(meetParser)
        }
    }
}
