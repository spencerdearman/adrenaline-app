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

private func encryptPasswordWithSalt(password: String, salt: Int64) -> String {
    let saltedPassword = password + String(salt)
    
    guard let saltedPasswordData = saltedPassword.data(using: .utf8) else { return "" }
    
    let hashedPassword = SHA256.hash(data: saltedPasswordData)
    let hashedPasswordString = hashedPassword.compactMap { String(format: "%02x", $0) }.joined()
    
    return hashedPasswordString
}

func encryptPassword(_ password: String) -> (String, Int64) {
    let salt = Int64.random(in: 0 ... Int64.max)
    let encryptedPassword = encryptPasswordWithSalt(password: password, salt: salt)
    
    if encryptedPassword == "" { return ("", -1) }
    return (encryptedPassword, salt)
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
        
        let result = try? moc.fetch(fetchRequest)
        
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
        guard let result = try? moc.fetch(fetchRequest) else {
            print("Failed to get result for meet")
            return
        }
        
        // Only adds to the database if the meet id doesn't already exist
        if result.count != 0 {
            print("Failed to add meet, meet id already exists")
            return
        }
        
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
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
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
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
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
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
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
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
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
        
        guard let result = try? moc.fetch(fetchRequest) else {
            print("Failed to get result of fetch request for user")
            return
        }
        
        if result.count != 0 {
            print("Failed to add user, email already exists")
            return
        }
        
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
    
    // Adds shell Athlete to the database (no recruiting, can be updated later)
    func addAthlete(firstName: String, lastName: String, email: String, phone: String?,
                    password: String) {
        let moc = container.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else {
            print("Failed to get result of fetch request for athlete")
            return
        }
        
        if result.count != 0 {
            print("Failed to add athlete, email already exists")
            return
        }
        
        let user = Athlete(context: moc)
        
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
    
    // Adds an Athlete to the database (with or without recruiting)
    func addAthlete(firstName: String, lastName: String, email: String, phone: String?,
                    password: String, heightFeet: Int?, heightInches: Int?, weight: Int?,
                    weightUnit: String?, gender: String?, age: Int?, gradYear: Int?,
                    highSchool: String?, hometown: String?) {
        let moc = container.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else {
            print("Failed to get result of fetch request for athlete")
            return
        }
        
        if result.count != 0 {
            print("Failed to add athlete, email already exists")
            return
        }
        
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
        user.springboardRating = 0.0
        user.platformRating = 0.0
        user.totalRating = 0.0
        
        try? moc.save()
    }
    
    func getUser(email: String) -> User? {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else { return nil }
        let resultData = result as! [User]
        if resultData.count != 1 {
            print("Failed to get User, result returned invalid number of results")
            return nil
        }
        
        return resultData[0]
    }
    
    func getAthlete(email: String) -> Athlete? {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else { return nil }
        let resultData = result as! [Athlete]
        if resultData.count != 1 {
            print("Failed to get Athlete, result returned invalid number of results")
            return nil
        }
        
        return resultData[0]
    }
    
    func getMaleAthletes() -> [Athlete]? {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "gender == %@", "Male")
        
        guard let result = try? moc.fetch(fetchRequest) else { return nil }
        let resultData = result as! [Athlete]
        if resultData.count == 0 { return nil }
        
        return resultData
    }
    
    func getFemaleAthletes() -> [Athlete]? {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
        fetchRequest.predicate = NSPredicate(format: "gender == %@", "Female")
        
        guard let result = try? moc.fetch(fetchRequest) else { return nil }
        let resultData = result as! [Athlete]
        if resultData.count == 0 { return nil }
        
        return resultData
    }
    
    func updateUserField(email: String, key: String, value: Any) {
        guard let user = getUser(email: email) else { return }
        user.setValue(value, forKey: key)
    }
    
    func updateAthleteField(email: String, key: String, value: Any?) {
        let moc = container.viewContext
        guard let athlete = getAthlete(email: email) else { return }
        athlete.setValue(value, forKey: key)
        
        try? moc.save()
    }
    
    func updateAthleteSkillRating(email: String, springboardRating: Double? = nil,
                                  platformRating: Double? = nil) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
        let resultData = result as! [Athlete]
        if resultData.count != 1 {
            print("Failed to get Athlete, result returned invalid number of results")
            return
        }
        
        let athlete = resultData[0]
        var keyValues: [String: Double] = [:]
        if let springboard = springboardRating {
            keyValues["springboardRating"] = springboard
        }
        if let platform = platformRating {
            keyValues["platformRating"] = platform
        }
        
        athlete.setValuesForKeys(keyValues)
        athlete.setValue(athlete.springboardRating + athlete.platformRating, forKey: "totalRating")
        
        try? moc.save()
    }
    
    // Drops the User with the given email username
    func dropUser(email: String) {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
        let resultData = result as! [User]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    func dropAllUsers() {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        
        guard let result = try? moc.fetch(fetchRequest) else { return }
        let resultData = result as! [User]
        
        for object in resultData {
            moc.delete(object)
        }
        
        try? moc.save()
    }
    
    func validatePassword(email: String, password: String) -> Bool {
        let moc = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        guard let result = try? moc.fetch(fetchRequest) else { return false }
        let resultData = result as! [User]
        if resultData.count != 1 {
            print("Failed to validate password, email matches to zero or more than one user")
            return false
        }
        
        let user = resultData[0]
        let storedPassword = user.password
        let storedPasswordSalt = user.passwordSalt
        
        return encryptPasswordWithSalt(password: password,
                                       salt: storedPasswordSalt) == storedPassword
    }
    
    // Purges the entire Model database
    func dropAllRecords() {
        dropAllMeetRecords()
        dropAllUsers()
    }
}

