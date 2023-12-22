//
//  NewSearch.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/24/23.
//

import SwiftUI
import UIKit
import AVKit
import Amplify

enum SearchScope: String, CaseIterable {
    case all, users, meets, teams, colleges
}

enum SearchItem: Hashable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String {
        if case .meet(let meet) = self {
            return meet.id
        } else if case .user(let user) = self {
            return user.id
        } else if case .team(let team) = self {
            return team.id
        } else if case .college(let college) = self {
            return college.id
        } else {
            return ""
        }
    }
    
    var title: String {
        if case .user(let user) = self {
            return user.firstName + " " + user.lastName
        } else if case .meet(let meet) = self {
            return meet.name
        } else if case .team(let team) = self {
            return team.name
        } else if case .college(let college) = self {
            return college.name
        } else {
            return ""
        }
    }
    
    var subtitle: String {
        if case .user(let user) = self {
            return user.accountType
        } else if case .meet(_) = self {
            return "Meet"
        } else if case .team(_) = self {
            return "Team"
        } else if case .college(_) = self {
            return "College"
        } else {
            return ""
        }
    }
    
    case user(NewUser)
    case meet(NewMeet)
    case team(NewTeam)
    case college(College)
}

struct NewSearchView: View {
    @Environment(\.newUsers) private var newUsers
    @Environment(\.newMeets) private var newMeets
    @Environment(\.newTeams) private var newTeams
    @Environment(\.colleges) private var colleges
    @State private var searchTerm = ""
    @State private var showResult: Bool = false
    @State private var selectedItem: SearchItem? = nil
    @State private var searchItems: [SearchItem] = []
    @State private var searchScope: SearchScope = .all
    @Binding var recentSearches: [SearchItem]
    @Namespace var namespace
    
    private func updateRecentSearches(item: SearchItem) {
        if let index = recentSearches.firstIndex(of: item) {
            recentSearches.remove(at: index)
        }
        
        recentSearches.insert(item, at: 0)
        
        // Keeps the three most recent searches
        if recentSearches.count > 5 {
            recentSearches.removeLast()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                content
                Spacer()
            }
        }
        .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search Adrenaline")
        .searchScopes($searchScope) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue.capitalized)
            }
        }
        .onAppear {
            searchItems = [
                .meet(NewMeet(meetID: 1, name: "Test Meet 1", startDate: Temporal.Date(Date()),
                              endDate: Temporal.Date(Date()),
                              city: "Pittsburgh", state: "PA", country: "United States",
                              link: "https://secure.meetcontrol.com/divemeets/system/meetinfoext.php?meetnum=9080", meetType: 2)),
                .meet(NewMeet(meetID: 2, name: "Test Meet 2", startDate: Temporal.Date(Date()),
                              endDate: Temporal.Date(Date()),
                              city: "Oakton", state: "VA", country: "United States",
                              link: "https://secure.meetcontrol.com/divemeets/system/meetinfoext.php?meetnum=9088", meetType: 2))
            ]
            
            searchItems += newMeets.map { .meet($0) }
            searchItems += newUsers.map { .user($0) }
            searchItems += newTeams.map { .team($0) }
            searchItems += colleges.map { .college($0) }
        }
    }
    
    var content: some View {
        ScrollView {
            VStack {
                if searchTerm.isEmpty {
                    ForEach(recentSearches) { item in
                        ListRow(title: item.title, icon: "clock.arrow.circlepath")
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showResult = true
                                selectedItem = item
                                updateRecentSearches(item: item)
                            }
                    }
                    .zIndex(3)
                }
                ForEach(results) { item in
                    ListRow(title: item.title, icon: "magnifyingglass")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showResult = true
                            selectedItem = item
                            updateRecentSearches(item: item)
                        }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 30)
            .padding(20)
            .navigationTitle("Search")
            .background(
                Rectangle()
                    .fill(.regularMaterial)
                    .frame(height: 200)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -200)
                    .blur(radius: 20)
            )
            .sheet(isPresented: $showResult) {
                presentedSearchItems
            }
        }
        .scrollIndicators(.hidden)
    }
    
    var closeButton: some View {
        return Button {
            showResult = false
            selectedItem = nil
        } label: {
            CloseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(25)
        .ignoresSafeArea()
    }
    
    private func getSearchItemView(item: SearchItem) -> any View {
        if case .meet(let meet) = item,
           let selected = selectedItem,
           meet.id == selected.id {
            return ZStack {
                NavigationView {
                    MeetPageView(meetLink: meet.link)
                }
            }
        } else if case .user(let user) = item,
                  let selected = selectedItem,
                  user.id == selected.id {
            return ZStack {
                AdrenalineProfileView(newUser: user)
                
                closeButton
            }
        } else if case .team(let team) = item,
                  let selected = selectedItem,
                  team.id == selected.id {
            return ZStack {
                Text(team.name)
                
                closeButton
            }
        } else if case .college(let college) = item,
                  let selected = selectedItem,
                  college.id == selected.id {
            return ZStack {
                Text(college.name)
                
                closeButton
            }
        } else {
            return EmptyView()
        }
    }
    
    var presentedSearchItems: some View {
        ForEach(searchItems) { item in
            AnyView(getSearchItemView(item: item))
        }
    }
    
    var results: [SearchItem] {
        if searchTerm.isEmpty {
            return searchItems
        } else if searchScope == .users {
            return searchItems.filter {
                if case .user(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(searchTerm)
                } else {
                    return false
                }
            }
        } else if searchScope == .meets {
            return searchItems.filter {
                if case .meet(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(searchTerm)
                } else {
                    return false
                }
            }
        } else if searchScope == .teams {
            return searchItems.filter {
                if case .team(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(searchTerm)
                } else {
                    return false
                }
            }
        } else if searchScope == .colleges {
            return searchItems.filter {
                if case .college(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(searchTerm)
                } else {
                    return false
                }
            }
        } else {
            return searchItems.filter { $0.title.localizedCaseInsensitiveContains(searchTerm) }
        }
    }
}

struct ListRow: View {
    var title: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .mask(Circle())
                .backgroundStyle(cornerRadius: 18)
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}
