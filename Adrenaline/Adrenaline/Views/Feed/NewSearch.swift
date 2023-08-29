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
    var id: String {
        if case .meet(let meet) = self {
            return meet.id.uuidString
        } else if case .user(let user) = self {
            return user.id.uuidString
        } else if case .team(let team) = self {
            return team.id.uuidString
        } else if case .college(let college) = self {
            return college.id.uuidString
        } else {
            return ""
        }
    }
    
    var title: String {
        if case .user(let user) = self {
            return user.email
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
    
    case user(GraphUser)
    case meet(GraphMeet)
    case team(GraphTeam)
    case college(GraphCollege)
}

struct NewSearchView: View {
    @Environment(\.graphUsers) private var graphUsers
    @State var text = ""
    @State var showResult: Bool = false
    @State var selectedItem: SearchItem? = nil
    @State var searchItems: [SearchItem] = []
    @State var searchScope: SearchScope = .all
    @State var recentSearches: [SearchItem] = []
    @Namespace var namespace
    
    private func updateRecentSearches(item: SearchItem) {
        if let index = recentSearches.firstIndex(of: item) {
            recentSearches.remove(at: index)
        }
        
        recentSearches.insert(item, at: 0)
        
        // Keeps the three most recent searches
        if recentSearches.count == 4 {
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
        .searchable(text: $text) {
            ForEach(suggestions) { suggestion in
                Button {
                    text = suggestion.title
                } label: {
                    ListRow(title: suggestion.title,
                            icon: text.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                        .foregroundColor(.primary)
                }
                .searchCompletion(suggestion.title)
            }
        }
        .searchScopes($searchScope) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue.capitalized)
            }
        }
        .onAppear {
            searchItems = [
                .meet(GraphMeet(meetID: 1, name: "Test Meet 1", startDate: Temporal.Date(Date()),
                                endDate: Temporal.Date(Date()),
                                city: "Pittsburgh", state: "PA", country: "United States",
                                link: "https://secure.meetcontrol.com/divemeets/system/meetinfoext.php?meetnum=9080", meetType: 2)),
                .meet(GraphMeet(meetID: 2, name: "Test Meet 2", startDate: Temporal.Date(Date()),
                                endDate: Temporal.Date(Date()),
                                city: "Oakton", state: "VA", country: "United States",
                                link: "https://secure.meetcontrol.com/divemeets/system/meetinfoext.php?meetnum=9088", meetType: 2)),
                .team(GraphTeam(name: "Pitt Aquatic Club")),
                .college(GraphCollege(name: "University of Chicago",
                                      imageLink: "https://www.google.com"))]
            
            searchItems += graphUsers.map { .user($0) }
        }
    }
    
    var content: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(results) { item in
                    if results.count != 0 {
                        Divider()
                    }
                    Button {
                        showResult = true
                        selectedItem = item
                        updateRecentSearches(item: item)
                    } label:  {
                        ListRow(title: item.title, icon: "magnifyingglass")
                    }
                    .buttonStyle(.plain)
                }
                
                if results.isEmpty {
                    Text("No results found")
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
           meet.id.uuidString == selected.id {
            return ZStack {
                NavigationView {
                    MeetPageView(meetLink: meet.link)
                }
            }
        } else if case .user(let user) = item,
                  let selected = selectedItem,
                  user.id.uuidString == selected.id {
                return ZStack {
                    Text(user.email)
                    
                    closeButton
                }
        } else if case .team(let team) = item,
                  let selected = selectedItem,
                  team.id.uuidString == selected.id {
            return ZStack {
                Text(team.name)
                
                closeButton
            }
        } else if case .college(let college) = item,
                  let selected = selectedItem,
                  college.id.uuidString == selected.id {
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
    
//    var feedItems: [FeedItem] {
//        var result: [FeedItem] = []
//
//        for item in searchItems {
//            if case .feedItem(let feedItem) = item {
//                result.append(feedItem)
//            }
//        }
//
//        return result
//    }
    
    var results: [SearchItem] {
        if text.isEmpty {
            return searchItems
        } else if searchScope == .users {
            return searchItems.filter {
                if case .user(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(text)
                } else {
                    return false
                }
            }
        } else if searchScope == .meets {
            return searchItems.filter {
                if case .meet(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(text)
                } else {
                    return false
                }
            }
        } else if searchScope == .teams {
            return searchItems.filter {
                if case .team(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(text)
                } else {
                    return false
                }
            }
        } else if searchScope == .colleges {
            return searchItems.filter {
                if case .college(_) = $0 {
                    return $0.title.localizedCaseInsensitiveContains(text)
                } else {
                    return false
                }
            }
        } else {
            return searchItems.filter { $0.title.localizedCaseInsensitiveContains(text) }
        }
    }
    
    var suggestions: [SearchItem] {
        if text.isEmpty {
            return recentSearches
        } else {
            return results.filter { $0.title.localizedCaseInsensitiveContains(text) }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NewSearchView()
    }
}

struct Suggestion: Identifiable {
    let id = UUID()
    var text: String
}

var suggestionsData = [
    Suggestion(text: "MEET 1"),
    Suggestion(text: "MEET 2"),
    Suggestion(text: "PERSON 1"),
    Suggestion(text: "PERSON 2")
]


struct ListRow: View {
    var title = "Development"
    var icon = "iphone"
    
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
