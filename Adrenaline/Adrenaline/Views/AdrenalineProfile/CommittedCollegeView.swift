//
//  CommittedCollegeView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 12/22/23.
//

import SwiftUI

let colleges: [String: String]? = getCollegeLogoData()

struct CommittedCollegeView: View {
    @State private var searchTerm: String = ""
    @Binding var selectedCollege: String
    
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
            let url = URL(string: colleges?[collegeName] ?? "")
            AsyncImage(url: url) { img in
                switch img {
                    case .success(let i):
                        i
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        Image(systemName: "exclamationmark.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                            .aspectRatio(contentMode: .fit)
                }
            }
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
