//
//  AdrenalineSearch.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/30/23.
//

import SwiftUI

struct AdrenalineSearch: View {
    @Environment(\.getUserByFirstName) private var getUserByFirstName
    @Environment(\.getUserByLastName) private var getUserByLastName
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var firstNameUsers: [User]? = []
    @State var lastNameUsers: [User]? = []
    @State var firstLastUsers: [User]? = []
    @State var results: [User]? = []
    @State var showResults: Bool = false
    @State var showError: Bool = false
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    @FocusState private var focusedField: SearchField?
    
    var body: some View {
        ZStack {
            BackgroundBubble() {
                VStack {
                    HStack {
                        Text("First Name:")
                            .padding([.leading, .bottom, .top])
                        TextField("First Name", text: $firstName)
                            .modifier(TextFieldClearButton(text: $firstName,
                                                           fieldType: .firstName,
                                                           focusedField: $focusedField))
                            .multilineTextAlignment(.leading)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                            .focused($focusedField, equals: .firstName)
                    }
                    HStack {
                        Text("Last Name:")
                            .padding([.leading])
                        TextField("Last Name", text: $lastName)
                            .modifier(TextFieldClearButton(text: $lastName,
                                                           fieldType: .lastName,
                                                           focusedField: $focusedField))
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .padding(.trailing)
                            .focused($focusedField, equals: .lastName)
                        
                    }
                    .padding(.bottom)
                    if showError {
                        Text("No Profiles Found")
                            .foregroundColor(.red)
                    }
                    Button {
                        showError = false
                        showResults = false
                        if firstName != "" && lastName == "" {
                            if let users = getUserByFirstName(firstName) {
                                firstNameUsers = users
                                results = firstNameUsers
                            } else {
                                print("First Name search not found")
                            }
                        } else if firstName == "" && lastName != "" {
                            if let lastUsers = getUserByLastName(lastName) {
                                lastNameUsers = lastUsers
                                results = lastNameUsers
                            } else {
                                print("Last Name search not found")
                            }
                        } else {
                            if let users = getUserByFirstName(firstName) {
                                firstNameUsers = users
                            } else {
                                print("First Name search not found")
                            }
                            
                            if let lastUsers = getUserByLastName(lastName) {
                                lastNameUsers = lastUsers
                            } else {
                                print("Last Name search not found")
                            }
                            if let firstNameUsers = firstNameUsers, let lastNameUsers = lastNameUsers {
                                for u in firstNameUsers {
                                    if lastNameUsers.contains(u) {
                                        firstLastUsers?.append(u)
                                    }
                                }
                            }
                            results = firstLastUsers
                        }
                        if results == [] {
                            showError = true
                        } else {
                            showResults = true
                        }
                    } label: {
                        Text("Search")
                    }
                    
                }
                .frame(width: screenWidth * 0.85)
                .dynamicTypeSize(.xSmall ... .xxxLarge)
            }
            if showResults {
                AdrenalineSearchResults(results: $results)
            }
        }
    }
}

struct AdrenalineSearchResults: View {
    @Environment(\.colorScheme) var currentMode
    @Binding var results: [User]?
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            SearchColorfulView()
            List(results ?? []) { user in
                Text((user.firstName ?? "") + " " + (user.lastName ?? ""))
            }
        }
    }
}
