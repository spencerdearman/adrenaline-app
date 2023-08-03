//
//  KeychainAccess.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/21/23.
//

import Foundation

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

// https://mukeshydv.medium.com/securing-users-data-in-ios-with-swift-9e2be41c3b31
func saveToKeychain(value: String?, for key: String?) throws {
    guard let key = key else { throw KeychainError.unexpectedPasswordData }
    guard let value = value else { throw KeychainError.unexpectedPasswordData }
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: value.data(using: String.Encoding.utf8)!
    ]
    
    var status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem {
        try updateKeychainItem(value: value, for: key)
        status = errSecSuccess
    }
    
    guard status == errSecSuccess else {
        throw KeychainError.unhandledError(status: status)
    }
}

func updateKeychainItem(value: String?, for key: String?) throws {
    guard let key = key else { throw KeychainError.unexpectedPasswordData }
    guard let value = value else { throw KeychainError.unexpectedPasswordData }
    
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
    let attributes: [String: Any] = [kSecAttrAccount as String: key,
                                     kSecValueData as String: value.data(using: String.Encoding.utf8)!]
    
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard status != errSecItemNotFound else { print("no password"); throw KeychainError.noPassword }
    guard status == errSecDuplicateItem || status == errSecSuccess else {
        throw KeychainError.unhandledError(status: status)
    }
}

func readFromKeychain(for key: String?) throws -> String {
    guard let key = key else { throw KeychainError.unexpectedPasswordData }
    
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecAttrAccount as String: key,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else { throw KeychainError.noPassword }
    guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    
    guard let existingItem = item as? [String : Any],
          let passwordData = existingItem[kSecValueData as String] as? Data,
          let password = String(data: passwordData, encoding: String.Encoding.utf8)
    else {
        throw KeychainError.unexpectedPasswordData
    }
    
    return password
}

func deleteFromKeychain(for key: String?) throws {
    guard let key = key else { throw KeychainError.unexpectedPasswordData }
    
    let query: [String: AnyObject] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key as AnyObject
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        print(status)
        throw KeychainError.unhandledError(status: status)
    }
}
