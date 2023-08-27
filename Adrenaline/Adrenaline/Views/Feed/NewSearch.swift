//
//  NewSearch.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/24/23.
//

import SwiftUI
import UIKit
import AVKit

enum SearchScope: String, CaseIterable {
    case all, users, meets, posts
}

enum SearchItem: Hashable, Identifiable {
    static func == (lhs: SearchItem, rhs: SearchItem) -> Bool {
        if case .feedItem(let left) = lhs,
           case .feedItem(let right) = rhs {
            return left == right
        } else if case .user(let left) = lhs,
                  case .user(let right) = rhs {
            return left == right
        } else {
            return false
        }
    }
    
    var id: Self {
        return self
    }
    
    var title: String {
        if case .user(let user) = self {
            return user.email
        } else if case .feedItem(let feedItem) = self {
            switch feedItem {
                case is MeetFeedItem:
                    let item = feedItem as! MeetFeedItem
                    return "Meet: \(item.meet.name)"
                case is MediaFeedItem:
                    let item = feedItem as! MediaFeedItem
                    
                    if case .text(let text) = item.media {
                        return "Text: \(text)"
                    } else {
                        return "Video: \(feedItem.id)"
                    }
                case is ImageFeedItem:
                    return "Image: \(feedItem.id)"
                case is SuggestedFeedItem:
                    return "Suggested: \(feedItem.id)"
                default:
                    return "Unknown: \(feedItem.id)"
            }
        } else {
            return ""
        }
    }
    
    case user(GraphUser)
    case feedItem(FeedItem)
}

struct NewSearchView: View {
    @Environment(\.graphUsers) private var graphUsers
    @State var text = ""
    @State var showItem = false
    @State var feedModel : FeedModel = FeedModel()
    @State var searchItems: [SearchItem] = []
    @State var users: [GraphUser] = []
    @State var selectedItem: SearchItem? = nil
    @State var searchScope: SearchScope = .all
    @Namespace var namespace
    
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
                    text = suggestion.text
                } label: {
                    Text(suggestion.text)
                }
                .searchCompletion(suggestion.text)
            }
        }
        .searchScopes($searchScope) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue.capitalized)
            }
        }
        .onChange(of: searchScope) { _ in
            print(searchScope)
        }
        .onAppear {
            searchItems = [
                .feedItem(MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                                       namespace: namespace, feedModel: $feedModel)),
                .feedItem(MediaFeedItem(media: Media.text("Hello World"),
                                        namespace: namespace, feedModel: $feedModel)),
                .feedItem(MediaFeedItem(media: Media.video(VideoPlayer(player: nil)),
                                        namespace: namespace, feedModel: $feedModel))]
            if case .feedItem(let item) = searchItems[0] {
                feedModel.selectedItem = item.id
            }
            users = graphUsers
            searchItems += users.map { .user($0) }
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
                        showItem = true
                        selectedItem = item
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
            .background(
                Image("Blob 1").offset(x: -100, y: -200)
                    .accessibility(hidden: true)
            )
            .sheet(isPresented: $showItem) {
                presentedFeedItems
            }
        }
    }
    
    var presentedFeedItems: some View {
        ForEach(feedItems) { item in
            if item.id == feedModel.selectedItem {
                AnyView(item.expandedView)
            }
        }
    }
    
    var feedItems: [FeedItem] {
        var result: [FeedItem] = []
        
        for item in searchItems {
            if case .feedItem(let feedItem) = item {
                result.append(feedItem)
            }
        }
        
        return result
    }
    
    var results: [SearchItem] {
        if text.isEmpty {
            return searchItems
        } else if searchScope == .users {
            return searchItems.filter {
                if case .user(_) = $0 {
                    return true
                } else {
                    return false
                }
            }
        } else if searchScope == .meets {
            return searchItems.filter {
                if case .feedItem(let item) = $0,
                   type(of: item) == MeetFeedItem.self {
                    return true
                } else {
                    return false
                }
            }
        } else if searchScope == .posts {
            return searchItems.filter {
                if case .feedItem(let item) = $0,
                   type(of: item) == MediaFeedItem.self || type(of: item) == ImageFeedItem.self {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return searchItems
        }
    }
    
    var suggestions: [Suggestion] {
        if text.isEmpty {
            return suggestionsData
        } else {
            return suggestionsData.filter { $0.text.localizedCaseInsensitiveContains(text) }
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
