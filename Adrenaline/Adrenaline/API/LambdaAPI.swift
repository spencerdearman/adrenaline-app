//
//  LambdaAPI.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 3/30/24.
//

import Foundation
import AWSLambda
import AWSPluginsCore

// https://github.com/aws-amplify/amplify-swift/issues/2847#issuecomment-1496570550
func invokeLambda(functionName: String, payload: Data? = nil) async throws {
    do {
        let authService: AWSAuthServiceBehavior = AWSAuthService()
        let credentialsProvider = authService.getCredentialsProvider()
        let configuration = try await LambdaClient.LambdaClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: "us-east-1"
        )
        let client = LambdaClient(config: configuration)
        
        let invokeInput = InvokeInput(
            functionName: functionName,
            invocationType: .event, // your invocation type
            payload: payload
        )
        let result = try await client.invoke(input: invokeInput)
        print("Result: ", result)
    } catch {
        print("Error: ", error)
    }
}

// Invokes delete-unconfirmed-user lambda with the given email as the userId argument in the lambda
func deleteUnconfirmedUser(email: String) async throws {
    let dict = ["userId": email]
    let encoder = JSONEncoder()
    if let jsonData = try? encoder.encode(dict) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        
        try await invokeLambda(functionName: "delete-unconfirmed-user", payload: jsonData)
    }
}
