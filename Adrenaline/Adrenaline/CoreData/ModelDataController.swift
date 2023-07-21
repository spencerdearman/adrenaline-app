//
//  ModelDataController.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/21/23.
//

import CoreData
import CryptoKit
import Foundation

enum RecordType: Int, CaseIterable {
    case upcoming = 0
    case current = 1
    case past = 2
    
}

//                      id  , name   , org    , link   , startDate, endDate, city , state  , country
typealias MeetRecord = (Int?, String?, String?, String?, String?, String?, String?, String?, String?)

//                             [(MeetRecord, resultsLink)]
typealias CurrentMeetRecords = [(MeetRecord, String?)]

func encryptPassword(_ password: String) -> (String, Int64) {
    let salt = Int64.random(in: 0 ... Int64.max)
    let saltedPassword = password + String(salt)
    
    guard let saltedPasswordData = saltedPassword.data(using: .utf8) else { return ("", -1) }
    
    let hashedPassword = SHA256.hash(data: saltedPasswordData)
    let hashedPasswordString = hashedPassword.compactMap { String(format: "%02x", $0) }.joined()
    
    return (hashedPasswordString, salt)
}

class ModelDataController: ObservableObject {
    let container = NSPersistentContainer(name: "Model")
    static var instances: Int? = nil
    
    init() {
        // Attempted guard at creating more than one instance of class
        if ModelDataController.instances == nil {
            ModelDataController.instances = 1
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("Core Data failed to load Meets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Updates an existing database's start/end dates with startOfDay times
    func fixDates(_ meet: DivingMeet) {
        let moc = container.viewContext
        let cal = Calendar(identifier: .gregorian)
        if let startDate = meet.startDate {
            meet.startDate = cal.startOfDay(for: startDate)
        }
        if let endDate = meet.endDate {
            meet.endDate = cal.startOfDay(for: endDate)
        }
        
        try? moc.save()
    }
    
    // Adds a single record to the CoreData database if meet id is not already present
    func addRecord(_ meetId: Int?, _ name: String?, _ org: String?, _ link: String?,
                   _ startDate: String?, _ endDate: String?, _ city: String?, _ state: String?,
                   _ country: String?, _ type: RecordType?) {
        let moc = container.viewContext
        let cal = Calendar(identifier: .gregorian)
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        
        // Check if the entry is already in the database before adding
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        let predicate = NSPredicate(format: "meetId == \(meetId == nil ? "%@" : "%d")",
                                    meetId ?? NSNull())
        fetchRequest.predicate = predicate
        
        var result = try? moc.fetch(fetchRequest)
        
        // Deletes all meets that match meetId and have a lower or equal type value
        // (upcoming < current < past)
        if let result = result, result.count > 0 {
            let resultData = result as! [DivingMeet]
            for meet in resultData {
                // Drop if less than or equal in case the meet has been updated since last stored
                // (i.e. change name, dates, etc. but not meet type status)
                if let type = type, Int(meet.meetType) <= type.rawValue {
                    dropDuplicateRecords(meetId)
                }
            }
        }
        
        // Refetch results after removing above
        result = try? moc.fetch(fetchRequest)
        
        // Only adds to the database if the meet id doesn't already exist
        if let result = result, result.count == 0 {
            let meet = DivingMeet(context: moc)
            
            meet.id = UUID()
            if let meetId = meetId {
                meet.meetId = Int32(meetId)
            }
            meet.name = name
            meet.organization = org
            meet.link = link
            if let type = type {
                meet.meetType = Int16(type.rawValue)
            }
            if let startDate = startDate, let date = df.date(from: startDate) {
                meet.startDate = cal.startOfDay(for: date)
            }
            if let endDate = endDate, let date = df.date(from: endDate) {
                meet.endDate = cal.startOfDay(for: date)
            }
            meet.city = city
            meet.state = state
            meet.country = country
            
            try? moc.save()
        }
    }
    
    // Adds a list of records to the CoreData database
    func addRecords(records: [MeetRecord], type: RecordType? = nil) {
        for record in records {
            let (meetId, name, org, link, startDate, endDate, city, state, country) = record
            addRecord(meetId, name, org, link, startDate, endDate, city, state, country, type)
        }
    }
    
    // Drops a record from the CoreData database
    func dropRecord(_ meetId: Int?, _ name: String?, _ org: String?, _ link: String?,
                    _ startDate: String?, _ endDate: String?, _ city: String?, _ state: String?,
                    _ country: String?) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        let cal = Calendar(identifier: .gregorian)
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        var startDateN: NSDate? = nil
        var endDateN: NSDate? = nil
        if let startDate = startDate, let date = df.date(from: startDate) {
            startDateN = cal.startOfDay(for: date) as NSDate
        }
        if let endDate = endDate, let date = df.date(from: endDate) {
            endDateN = cal.startOfDay(for: date) as NSDate
        }
        
        // Add formatting here so we can properly format nil if meetId or year is nil
        let formatPredicate =
        "meetId == \(meetId == nil ? "%@" : "%d") AND name == %@ AND organization == %@ AND "
        + "link == %@ AND startDate == %@ AND endDate == %@ AND city == %@ AND state == %@ AND "
        + "country == %@"
        let predicate = NSPredicate(
            format: formatPredicate, meetId ?? NSNull(), name ?? NSNull(), org ?? NSNull(),
            link ?? NSNull(), startDateN ?? NSNull(), endDateN ?? NSNull(), city ?? NSNull(),
            state ?? NSNull(), country ?? NSNull())
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
            let (meetId, name, org, link, startDate, endDate, city, state, country) = record
            dropRecord(meetId, name, org, link, startDate, endDate, city, state, country)
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
    
    // Drops records with matching meet ids
    // keepLatest will drop duplicates and keep the latest version (false when adding records)
    func dropDuplicateRecords(_ meetId: Int?, keepLatest: Bool = false) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        let predicate = NSPredicate(format: "meetId == \(meetId == nil ? "%@" : "%d")",
                                    meetId ?? NSNull())
        fetchRequest.predicate = predicate
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        var latestTypeIdx: Int = -1
        var latestType: Int16 = -1
        if keepLatest {
            // Finds highest meet type value of the duplicates and saves its index to keep
            for (i, object) in resultData.enumerated() {
                if latestType < object.meetType {
                    latestType = object.meetType
                    latestTypeIdx = i
                }
            }
        }
        
        for (i, object) in resultData.enumerated() {
            if keepLatest && i == latestTypeIdx { continue }
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Drops all records from the database
    func dropAllMeetRecords() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DivingMeet")
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [DivingMeet]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Turns MeetDict into [(meetId, name, org, link, startDate, endDate, city, state, country)]
    func dictToTuple(dict: MeetDict) -> [MeetRecord] {
        var result: [MeetRecord] = []
        for (_, orgDict) in dict {
            for (org, meetDict) in orgDict {
                for (name, link, startDate, endDate, city, state, country) in meetDict {
                    if let linkSplit = link.split(separator: "=").last {
                        if let meetId = Int(linkSplit) {
                            result.append(
                                (meetId, name, org, link, startDate, endDate, city, state, country))
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    // Turns CurrentMeetDict into
    // [(meetId, name, <nil>, link, startDate, endDate, city, state, country)]
    // ** link is info link for meet, results link is not stored in the database if it exists
    func dictToTuple(dict: CurrentMeetList) -> [MeetRecord] {
        var result: [MeetRecord] = []
        for elem in dict {
            for (name, typeDict) in elem {
                for (typ, (link, startDate, endDate, city, state, country)) in typeDict {
                    if typ == "results" {
                        continue
                    }
                    if let linkSplit = link.split(separator: "=").last {
                        if let meetId = Int(linkSplit) {
                            result.append(
                                (meetId, name, nil, link, startDate, endDate, city, state, country))
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    // Adds a generic User to database (coach, spectator)
    func addUser(firstName: String, lastName: String, email: String, phone: String?,
                 password: String) {
        let moc = container.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        let result = try? moc.fetch(fetchRequest)
        
        if let result = result, result.count == 0 {
            let user = User(context: moc)
            
            user.id = UUID()
            user.firstName = firstName
            user.lastName = lastName
            user.email = email
            user.phone = phone
            let (encryptedPassword, salt) = encryptPassword(password)
            user.password = encryptedPassword
            user.passwordSalt = salt
            
            try? moc.save()
        }
    }
    
    // Adds an Athlete to the database (with or without recruiting)
    func addAthlete(firstName: String, lastName: String, email: String, phone: String?,
                    password: String, heightFeet: Int?, heightInches: Int?, weight: Int?,
                    weightUnit: String?, gender: String?, age: Int?, gradYear: Int?,
                    highSchool: String?, hometown: String?) {
        let moc = container.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        let result = try? moc.fetch(fetchRequest)
        
        if let result = result, result.count == 0 {
            let user = Athlete(context: moc)
            
            user.id = UUID()
            user.firstName = firstName
            user.lastName = lastName
            user.email = email
            user.phone = phone
            let (encryptedPassword, salt) = encryptPassword(password)
            user.password = encryptedPassword
            user.passwordSalt = salt
            
            if let feet = heightFeet { user.heightFeet = Int16(feet) }
            if let inches = heightInches { user.heightInches = Int16(inches) }
            if let weight = weight { user.weight = Int16(weight) }
            user.weightUnit = weightUnit
            user.gender = gender
            if let age = age { user.age = Int16(age) }
            if let gradYear = gradYear { user.graduationYear = Int16(gradYear) }
            user.highSchool = highSchool
            user.hometown = hometown
            
            try? moc.save()
        }
    }
    
    // Drops the User with the given email username
    func dropUser(email: String) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [User]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    func dropAllUsers() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [User]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    // Purges the entire Model database
    func dropAllRecords() {
        dropAllMeetRecords()
        dropAllUsers()
    }
}

