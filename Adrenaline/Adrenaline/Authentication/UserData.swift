//
//  UserData.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/10/23.
//

import SwiftUI
import Combine


class UserData: ObservableObject {
    @Published var signedIn: Bool = false
}
