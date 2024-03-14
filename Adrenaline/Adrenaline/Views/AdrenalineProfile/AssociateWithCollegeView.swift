//
//  AssociateWithCollegeView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 3/10/24.
//

import SwiftUI
import Amplify

struct AssociateWithCollegeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var coachUser: CoachUser? = nil
    @State private var searchTerm: String = ""
    @State private var originalSelectedCollege: String = ""
    @State private var selectedCollege: String = ""
    @State private var showAlert: Bool = false
    @State private var isRequestingAssociation: Bool = false
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
            currentAssociationView
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
            
            if selectedCollege != "" {
                Button {
                    Task {
                        isRequestingAssociation = true
                        try await uploadCollegeAssociationRequest(
                            userId: newUser.id,
                            selectedCollegeId: getCollegeId(name: selectedCollege)
                        )
                        showAlert = true
                        isRequestingAssociation = false
                    }
                } label: {
                    ColorfulButton(title: "Request Association")
                }
                .disabled(isRequestingAssociation)
            }
        }
        .searchable(text: $searchTerm, prompt: "Search Colleges")
        .alert("College Association Request submitted. Our support team will verify your association and update your profile if approved.",
               isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
                dismiss()
            }
        }
        .onAppear {
            Task {
                coachUser = try await newUser.coach
                originalSelectedCollege = try await coachUser?.college?.name ?? ""
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
    
    var currentAssociationView: some View {
        VStack {
            Text("Current Association")
                .foregroundColor(.primary)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            if originalSelectedCollege == "" {
                noSelectionView
            } else {
                CollegeRowView(collegeName: originalSelectedCollege)
            }
        }
    }
}
