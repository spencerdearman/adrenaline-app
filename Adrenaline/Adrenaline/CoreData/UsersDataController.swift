////
////  UsersDataController.swift
////  Adrenaline
////
////  Created by Logan Sherwin on 7/21/23.
////
//
//import CoreData
//import CryptoKit
//import Foundation
//
//func encryptPassword(_ password: String) -> (String, Int64) {
//    let salt = Int64.random(in: 0 ... Int64.max)
//    let saltedPassword = password + String(salt)
//    
//    guard let saltedPasswordData = saltedPassword.data(using: .utf8) else { return ("", -1) }
//    
//    let hashedPassword = SHA256.hash(data: saltedPasswordData)
//    let hashedPasswordString = hashedPassword.compactMap { String(format: "%02x", $0) }.joined()
//    
//    return (hashedPasswordString, salt)
//}
//
//class UsersDataController: ObservableObject {
////    let container = NSPersistentContainer(name: "Model")
//    static var instances: Int? = nil
//    
//    init() {
//        if UsersDataController.instances == nil {
//            UsersDataController.instances = 1
//            container.loadPersistentStores { description, error in
//                if let error = error {
//                    print("Core Data failed to load Users: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    // Adds a generic User to database (coach, spectator)
//    func addUser(firstName: String, lastName: String, email: String, phone: String?,
//                 password: String) {
//        let moc = container.viewContext
//        
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
//        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
//        
//        var result = try? moc.fetch(fetchRequest)
//        
//        if let result = result, result.count == 0 {
//            let user = User(context: moc)
//            
//            user.id = UUID()
//            user.firstName = firstName
//            user.lastName = lastName
//            user.email = email
//            user.phone = phone
//            let (encryptedPassword, salt) = encryptPassword(password)
//            user.password = encryptedPassword
//            user.passwordSalt = salt
//            
//            try? moc.save()
//        }
//    }
//    
//    // Adds an Athlete to the database (with or without recruiting)
//    func addAthlete(firstName: String, lastName: String, email: String, phone: String?,
//                 password: String, heightFeet: Int?, heightInches: Int?, weight: Int?,
//                 weightUnit: String?, gender: String?, age: Int?, gradYear: Int?,
//                 highSchool: String?, hometown: String?) {
//        let moc = container.viewContext
//        
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Athlete")
//        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
//        
//        var result = try? moc.fetch(fetchRequest)
//        
//        if let result = result, result.count == 0 {
//            let user = Athlete(context: moc)
//            
//            user.id = UUID()
//            user.firstName = firstName
//            user.lastName = lastName
//            user.email = email
//            user.phone = phone
//            let (encryptedPassword, salt) = encryptPassword(password)
//            user.password = encryptedPassword
//            user.passwordSalt = salt
//            
//            if let feet = heightFeet { user.heightFeet = Int16(feet) }
//            if let inches = heightInches { user.heightInches = Int16(inches) }
//            if let weight = weight { user.weight = Int16(weight) }
//            user.weightUnit = weightUnit
//            user.gender = gender
//            if let age = age { user.age = Int16(age) }
//            if let gradYear = gradYear { user.graduationYear = Int16(gradYear) }
//            user.highSchool = highSchool
//            user.hometown = hometown
//            
//            try? moc.save()
//        }
//    }
//    
//    // Drops the User with the given email username
//    func dropUser(email: String) {
//        let moc = container.viewContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
//        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
//        
//        let result = try? moc.fetch(fetchRequest)
//        let resultData = result as! [User]
//        
//        for object in resultData {
//            moc.delete(object)
//        }
//        
//        try? moc.save()
//    }
//    
//    func dropAllUsers() {
//        let moc = container.viewContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
//        
//        let result = try? moc.fetch(fetchRequest)
//        let resultData = result as! [User]
//        
//        for object in resultData {
//            moc.delete(object)
//        }
//        
//        try? moc.save()
//    }
//}
