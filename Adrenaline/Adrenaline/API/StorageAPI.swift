//
//  StorageAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/27/24.
//

import Foundation
import Amplify
import AWSS3StoragePlugin

func getPhotoIdKey(userId: String) -> String {
    return "id-cards/\(userId).jpg"
}

func getProfilePictureReviewKey(userId: String) -> String {
    return "profile-pics-under-review/\(userId).jpg"
}

func getProfilePictureKey(userId: String) -> String {
    return "profile-pictures/\(userId).jpg"
}

func getProfilePictureURL(userId: String) -> String {
    return "\(CLOUDFRONT_PROFILE_PICS_BASE_URL)/\(userId).jpg"
}

// Upload photo ID to S3
func uploadPhotoId(data: Data, userId: String) async throws {
    let key = getPhotoIdKey(userId: userId)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Photo ID for \(userId) uploaded")
}

// Upload profile picture to S3 to be reviewed for identity verification
func uploadProfilePictureForReview(data: Data, userId: String) async throws {
    let key = getProfilePictureReviewKey(userId: userId)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Profile picture for \(userId) uploaded for review")
}

// Delete profile picture under review from S3
func deleteProfilePictureInReview(userId: String) async throws {
    let key = getProfilePictureReviewKey(userId: userId)
    try await Amplify.Storage.remove(key: key)
    print("Profile picture for \(userId) removed from review")
}

// Upload profile picture to S3
func uploadProfilePicture(data: Data, userId: String) async throws {
    let key = getProfilePictureKey(userId: userId)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Profile picture for \(userId) uploaded")
}

func hasProfilePicture(userId: String) async -> Bool {
    do {
        let _ = try await Amplify.Storage.getURL(
            key: getProfilePictureKey(userId: userId),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    validateObjectExistence: true
                )
            )
        )
        
        return true
    } catch {
        print("User does not have profile picture")
    }
    
    return false
}
