//
//  UserSettingsPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 3/15/24.
//

import SwiftUI

struct UserSettingsPage: View {
    
    var newUser: NewUser?
    @Binding var updateDataStoreData: Bool
    @Binding var selectedCollege: String
    
    var body: some View {
        List {
            Section {
                if let user = newUser {
                    NavigationLink {
                        EditProfileView(updateDataStoreData: $updateDataStoreData,
                                        newUser: newUser)
                    } label: {
                        Label("Athletic Profile", systemImage: "figure.water.fitness")
                    }
                    .navigationTitle("Profile")
                    
                    NavigationLink {
                        EditAcademicsView(updateDataStoreData: $updateDataStoreData,
                                          newUser: newUser)
                    } label: {
                        Label("Academic Profile", systemImage: "book")
                    }
                    .navigationTitle("Profile")
                    
                    NavigationLink {
                        CommittedCollegeView(selectedCollege: $selectedCollege,
                                             updateDataStoreData: $updateDataStoreData,
                                             newUser: user)
                    } label: {
                        Label("Change Committed College", systemImage: "graduationcap")
                    }
                }
            }
            .listRowSeparator(.automatic)
        }
        .listStyle(.insetGrouped)
    }
}
