//
//  MeetsDataController.swift
//  PastMeets
//
//  Created by Logan Sherwin on 4/3/23.
//

import CoreData
import Foundation

enum RecordType: Int, CaseIterable {
    case upcoming = 0
    case current = 1
    case past = 2
    
}

// Type is not included, will be added in addRecord(s) before added to the database
typealias MeetRecord = (Int?, String?, String?, Int?, String?)

class MeetsDataController: ObservableObject {
    let container = NSPersistentContainer(name: "Meets")
    static var instances: Int? = nil
    
    init() {
        // Attempted guard at creating more than one instance of class
        if MeetsDataController.instances == nil {
            MeetsDataController.instances = 1
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Core Data failed to load Meets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Adds a single record to the CoreData database if not already present
    func addRecord(_ meetId: Int?, _ name: String?, _ org: String?, _ year: Int?, _ link: String?,
                   _ type: RecordType?) {
        let moc = container.viewContext
        
        // Check if the entry is already in the database before adding
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let formatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") && name == %@ AND "
        + "year == \(meetId == nil ? "%@" : "%d") AND link == %@"
        // Formatting for post-typechecking refetch
        let postTypeCheckFormatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") && name == %@ AND organization == %@ AND "
        + "year == \(meetId == nil ? "%@" : "%d") AND link == %@"
        // Cannot match on organization because meet status changes organization
        let predicate = NSPredicate(
            format: formatPredicate, meetId ?? NSNull(), name ?? NSNull(), year ?? NSNull(),
            link ?? NSNull())
        let postTypeCheckPredicate = NSPredicate(
            format: postTypeCheckFormatPredicate, meetId ?? NSNull(), name ?? NSNull(),
            org ?? NSNull(), year ?? NSNull(), link ?? NSNull())
        fetchRequest.predicate = predicate
        
        var result = try? moc.fetch(fetchRequest)
        
        // Deletes all meets that match in every field but organization and type and deletes all
        // meets that have a lower type value (upcoming < current < past)
        if result!.count > 0 {
            let resultData = result as! [DivingMeet]
            for meet in resultData {
                if type != nil && Int(meet.meetType) < type!.rawValue {
                    moc.delete(meet)
                }
            }
        }
        
        // Refetch results after removing above, including organization
        fetchRequest.predicate = postTypeCheckPredicate
        result = try? moc.fetch(fetchRequest)
        
        // Only adds to the database if it couldn't be found already (exact duplicates)
        if result!.count == 0 {
            let meet = DivingMeet(context: moc)
            meet.id = UUID()
            if meetId != nil {
                meet.meetId = Int32(meetId!)
            }
            meet.name = name
            meet.organization = org
            if year != nil {
                meet.year = Int16(year!)
            }
            meet.link = link
            if type != nil {
                meet.meetType = Int16(type!.rawValue)
            }
            
            try? moc.save()
        }
    }
    
    // Adds a list of records to the CoreData database
    func addRecords(records: [MeetRecord], type: RecordType? = nil) {
        for record in records {
            let (meetId, name, org, year, link) = record
            addRecord(meetId, name, org, year, link, type)
        }
    }
    
    // Drops a record from the CoreData database
    func dropRecord(
        _ meetId: Int?, _ name: String?, _ org: String?, _ year: Int?, _ link: String?) {
            let moc = container.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
            
            // Add formatting here so we can properly format nil if meetId or year is nil
            let formatPredicate =
            "meetId == \(meetId == nil ? "%@" : "%d") && name == %@ AND organization == %@ AND "
            + "year == \(meetId == nil ? "%@" : "%d") AND link == %@"
            let predicate = NSPredicate(
                format: formatPredicate, meetId ?? NSNull(), name ?? NSNull(), org ?? NSNull(),
                year ?? NSNull(), link ?? NSNull())
            fetchRequest.predicate = predicate
            
            let result = try? moc.fetch(fetchRequest)
            let resultData = result as! [DivingMeet]
            
            for object in resultData {
                moc.delete(object)
            }
            
            try? moc.save()
        }
    
    // Drops a list of records from the CoreData database
    func dropRecords(records: [MeetRecord]) {
        for record in records {
            let (meetId, name, org, year, link) = record
            dropRecord(meetId, name, org, year, link)
        }
    }
    
    func dropNullOrgRecords() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let predicate = NSPredicate(format: "organization == nil")
        fetchRequest.predicate = predicate
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Drops all records from the database
    func dropAllRecords() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Turns MeetDict into [(meetId, name, org, year, link)]
    func dictToTuple(dict: MeetDict) -> [MeetRecord] {
        var result: [MeetRecord] = []
        for (year, orgDict) in dict {
            for (org, meetDict) in orgDict {
                for (name, link) in meetDict {
                    let meetId: Int = Int(link.split(separator: "=").last!)!
                    result.append((meetId, name, org, Int(year)!, link))
                }
            }
        }
        
        return result
    }
    
    // Turns CurrentMeetDict into [(meetId, name, <nil>, year, link)] ** link is info link for meet
    func dictToTuple(dict: CurrentMeetDict) -> [MeetRecord] {
        let currentYear = Calendar.current.component(.year, from: Date())
        var result: [MeetRecord] = []
        for elem in dict {
            for (name, typeDict) in elem {
                for (typ, link) in typeDict {
                    if typ == "results" {
                        continue
                    }
                    let meetId: Int = Int(link.split(separator: "=").last!)!
                    result.append((meetId, name, nil, currentYear, link))
                }
            }
        }
        
        return result
    }
}
