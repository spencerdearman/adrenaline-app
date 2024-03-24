//
//  StorageAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/27/24.
//

import Foundation
import Amplify
import AWSS3StoragePlugin

func getDateOfBirthString(_ dateOfBirth: Temporal.Date) -> String {
    return dateOfBirth.iso8601FormattedString(format: .short, timeZone: .utc)
}

func getPhotoIdKey(userId: String,
                   firstName: String, lastName: String, dateOfBirth: Temporal.Date) -> String {
    return "id-cards/\(userId)_\(firstName)_\(lastName)_\(getDateOfBirthString(dateOfBirth)).jpg"
}

func getProfilePictureReviewKey(userId: String, firstName: String,
                                lastName: String, dateOfBirth: Temporal.Date) -> String {
    return "profile-pics-under-review/\(userId)_\(firstName)_\(lastName)_\(getDateOfBirthString(dateOfBirth)).jpg"
}

func getProfilePictureKey(userId: String, firstName: String,
                          lastName: String, dateOfBirth: Temporal.Date) -> String {
    return "profile-pictures/\(userId)_\(firstName)_\(lastName)_\(getDateOfBirthString(dateOfBirth)).jpg"
}

func getProfilePictureURL(userId: String, firstName: String, lastName: String,
                          dateOfBirth: Temporal.Date) -> String {
    return "\(CLOUDFRONT_PROFILE_PICS_BASE_URL)/\(userId)_\(firstName)_\(lastName)_\(getDateOfBirthString(dateOfBirth)).jpg"
}

// Upload photo ID to S3
func uploadPhotoId(data: Data, userId: String, firstName: String, lastName: String,
                   dateOfBirth: Temporal.Date) async throws {
    let key = getPhotoIdKey(userId: userId, firstName: firstName, lastName: lastName,
                            dateOfBirth: dateOfBirth)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Photo ID for \(userId) uploaded")
}

// Upload profile picture to S3 to be reviewed for identity verification
func uploadProfilePictureForReview(data: Data, userId: String, firstName: String, 
                                   lastName: String, dateOfBirth: Temporal.Date) async throws {
    let key = getProfilePictureReviewKey(userId: userId, firstName: firstName,
                                         lastName: lastName, dateOfBirth: dateOfBirth)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Profile picture for \(userId) uploaded for review")
}

// Delete profile picture under review from S3
func deleteProfilePictureInReview(userId: String, firstName: String,
                                  lastName: String, dateOfBirth: Temporal.Date) async throws {
    let key = getProfilePictureReviewKey(userId: userId, firstName: firstName,
                                         lastName: lastName, dateOfBirth: dateOfBirth)
    try await Amplify.Storage.remove(key: key)
    print("Profile picture for \(userId) removed from review")
}

// Upload profile picture to S3
func uploadProfilePicture(data: Data, userId: String, firstName: String,
                          lastName: String, dateOfBirth: Temporal.Date) async throws {
    let key = getProfilePictureKey(userId: userId, firstName: firstName,
                                   lastName: lastName, dateOfBirth: dateOfBirth)
    let task = Amplify.Storage.uploadData(key: key, data: data)
    
    let _ = try await task.value
    print("Profile picture for \(userId) uploaded")
}

func hasProfilePictureInReview(userId: String, firstName: String,
                               lastName: String, dateOfBirth: Temporal.Date) async -> Bool {
    do {
        let _ = try await Amplify.Storage.getURL(
            key: getProfilePictureReviewKey(userId: userId, firstName: firstName,
                                            lastName: lastName, dateOfBirth: dateOfBirth),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    validateObjectExistence: true
                )
            )
        )
        
        return true
    } catch {
        print("User does not have profile picture in review")
    }
    
    return false
}

func hasProfilePicture(userId: String, firstName: String,
                       lastName: String, dateOfBirth: Temporal.Date) async -> Bool {
    do {
        let _ = try await Amplify.Storage.getURL(
            key: getProfilePictureKey(userId: userId, firstName: firstName,
                                      lastName: lastName, dateOfBirth: dateOfBirth),
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

func deletePhotoId(userId: String, firstName: String, lastName: String,
                   dateOfBirth: Temporal.Date) async throws {
    let key = getPhotoIdKey(userId: userId, firstName: firstName, lastName: lastName,
                            dateOfBirth: dateOfBirth)
    try await Amplify.Storage.remove(key: key)
}

func uploadCollegeAssociationRequest(userId: String, selectedCollegeId: String) async throws {
    let task = Amplify.Storage.uploadData(
        key: "college-association-requests/\(userId)_\(selectedCollegeId).txt",
        data: Data()
    )
    
    let _ = try await task.value
    print("College association request uploaded")
}
