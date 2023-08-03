//
//  Account.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/26/23.
//

import SwiftUI

struct SignupData: Hashable {
    var accountType: AccountType?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var password: String?
    var recruiting: RecruitingData?
    
    func save() {
        guard let email = email, let password = password else { print("empty"); return }
        saveCredentials(email: email, password: password)
    }
    
    func clear() {
        guard let email = email else { return }
        clearCredentials(email: email)
    }
}

struct LoginData: Hashable {
    var username: String?
    var password: String?
    
    mutating func loadStoredCredentials() {
        guard let (username, password) = getStoredCredentials() else { return }
        self.username = username
        self.password = password
    }
}

struct RecruitingData: Hashable {
    var height: Height?
    var weight: Weight?
    var gender: String?
    var age: Int?
    var gradYear: Int?
    var highSchool: String?
    var hometown: String?
}

struct Height: Hashable {
    var feet: Int
    var inches: Int
}

struct Weight: Hashable {
    var weight: Int
    var unit: WeightUnit
}

func saveCredentials(email: String, password: String, defaults: UserDefaults = .standard) {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(email)  {
        defaults.set(encoded, forKey: "username")
    }
    
    do {
        try saveToKeychain(value: password, for: email)
    } catch {
        print("Unable to save password to keychain")
    }
}

func clearCredentials(email: String, defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: "username")
    do {
        try deleteFromKeychain(for: email)
    } catch {
        print("Unable to delete password from keychain")
    }
}

func getStoredCredentials(defaults: UserDefaults = .standard) -> (String, String)? {
    var username: String = ""
    var password: String = ""
    let decoder = JSONDecoder()
    if let data = defaults.data(forKey: "username") {
        guard let email = try? decoder.decode(String.self, from: data) else { return nil }
        username = email
    } else {
        return nil
    }
    
    do {
        password = try readFromKeychain(for: username)
    } catch {
        print("Failed to get password from keychain")
        return nil
    }
    
    return (username, password)
}
