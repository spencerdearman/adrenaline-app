//
//  SourceOfTruth.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import Amplify
import Foundation


class SourceOfTruth: ObservableObject {
    @Published var messages = [Message]()
}
