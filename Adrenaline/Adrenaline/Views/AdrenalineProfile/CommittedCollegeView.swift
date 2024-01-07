//
//  CommittedCollegeView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 12/22/23.
//

import SwiftUI
import Amplify

let colleges: [String: String]? = getCollegeLogoData()

struct CommittedCollegeView: View {
    @State private var newAthlete: NewAthlete? = nil
    @State private var searchTerm: String = ""
    @State private var originalSelectedCollege: String = ""
    @Binding var selectedCollege: String
    @Binding var updateDataStoreData: Bool
    var newUser: NewUser
    
    private let screenWidth = UIScreen.main.bounds.width
    
    private var collegeNames: [String]? {
        guard let colleges = colleges else { return nil }
        return Array(colleges.keys.sorted { $0 < $1 })
    }
    
    private var filteredCollegeNames: [String]? {
        guard let collegeNames = collegeNames else { return nil }
        guard !searchTerm.isEmpty else { return collegeNames }
        return collegeNames.filter { $0.localizedCaseInsensitiveContains(searchTerm) }
    }
    
    var body: some View {
        VStack {
            currentSelectionView
                .padding(.bottom)
            
            ScrollView {
                LazyVStack {
                    // Only show the "No Selection" option if user is not searching
                    if searchTerm.isEmpty {
                        Divider()
                            .padding(.bottom)
                        
                        noSelectionView
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(selectedCollege == "" ? Color.secondary : .clear,
                                            lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedCollege = ""
                            }
                    }
                    
                    // If there are results returned from the search
                    if let filtered = filteredCollegeNames, filtered.count > 0 {
                        ForEach(filtered, id: \.self) { college in
                            CollegeRowView(collegeName: college)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 40)
                                        .stroke(selectedCollege == college ? Color.secondary : .clear,
                                                lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedCollege = college
                                }
                        }
                        // If no results come back from the search
                    } else if let _ = filteredCollegeNames {
                        VStack {
                            Text("No results found")
                            Text("Please try a different search term")
                        }
                        .foregroundColor(.secondary)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding()
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .modifier(OutlineOverlay(cornerRadius: 30))
                        .backgroundStyle(cornerRadius: 30)
                        .padding(20)
                    }
                }
                .padding(.top)
            }
        }
        .searchable(text: $searchTerm, prompt: "Search Colleges")
        .onAppear {
            Task {
                originalSelectedCollege = selectedCollege
                newAthlete = try await newUser.athlete
            }
        }
        .onDisappear {
            Task {
                // If there was a change in selection, handle updating the DataStore
                if var athlete = newAthlete, selectedCollege != originalSelectedCollege {
                    var originalCollege: College? = nil
                    var newCollege: College? = nil
                    
                    if originalSelectedCollege != "" {
                        originalCollege = try await queryAWSCollegeById(id: getCollegeId(
                            name: originalSelectedCollege))
                    }
                    
                    if selectedCollege != "" {
                        newCollege = try await queryAWSCollegeById(id: getCollegeId(
                            name: selectedCollege))
                    }
                    
                    // If the user has selected a new college and the new college does not exist
                    // yet, create it with an empty athletes list
                    if selectedCollege != "",
                       newCollege == nil,
                       let imageLink = colleges?[selectedCollege] {
                        let college = College(id: getCollegeId(name: selectedCollege),
                                              name: selectedCollege,
                                              imageLink: imageLink)
                        newCollege = try await saveToDataStore(object: college)
                    }
                    
                    // If originalCollege was not None, remove athlete from its athletes list
                    if var college = originalCollege {
                        try await college.athletes?.fetch()
                        
                        if let athletes = college.athletes {
                            college.athletes = List<NewAthlete>.init(elements:
                                                                        athletes.elements.filter {
                                $0.id != athlete.id
                            })
                            
                            let _ = try await saveToDataStore(object: college)
                        }
                    }
                    
                    // If newCollege is not None, add athlete to its athletes list
                    if var college = newCollege {
                        try await college.athletes?.fetch()
                        
                        if let athletes = college.athletes {
                            college.athletes = List<NewAthlete>.init(elements: athletes.elements +
                                                                     [athlete])
                            
                            let _ = try await saveToDataStore(object: college)
                        }
                    }
                    
                    athlete.setCollege(newCollege)
                    let newAthlete = try await saveToDataStore(object: athlete)
                    var user = newUser
                    user.setAthlete(newAthlete)
                    let _ = try await saveToDataStore(object: user)
                    updateDataStoreData = true
                }
            }
        }
    }
    
    var noSelectionView: some View {
        HStack {
            Image(systemName: "x.circle.fill")
                .resizable()
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
                .aspectRatio(contentMode: .fit)
                .padding(.trailing)
            
            Text("None")
                .padding()
                .multilineTextAlignment(.leading)
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Custom.darkGray)
                .shadow(radius: 5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 40))
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.2)
    }
    
    var currentSelectionView: some View {
        VStack {
            Text("Current Selection")
                .foregroundColor(.primary)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            if selectedCollege == "" {
                noSelectionView
            } else {
                CollegeRowView(collegeName: selectedCollege)
            }
        }
    }
}

struct CollegeRowView: View {
    var collegeName: String
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        HStack {
            Image(getCollegeImageFilename(name: collegeName))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(Circle())
                .padding(.trailing)
            
            Text(collegeName)
                .padding()
                .multilineTextAlignment(.leading)
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Custom.darkGray)
                .shadow(radius: 5)
        )
        .frame(width: screenWidth * 0.9, height: screenWidth * 0.2)
    }
}
