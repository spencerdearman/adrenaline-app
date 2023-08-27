//
//  NewSearch.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/24/23.
//

import SwiftUI
import UIKit
import AVKit

struct NewSearchView: View {
    @State var text = ""
    @State var showItem = false
    @State var feedModel : FeedModel = FeedModel()
    @State var feedItems: [FeedItem] = []
    @State var selectedItem: FeedItem = FeedItem()
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
    }
    
    var content: some View {
        VStack {
            ForEach(results) { item in
                if results.count != 0 {
                    Divider()
                }
                Button {
                    showItem = true
                    selectedItem = item
                } label:  {
                    ListRow(title: "ITEM TITLE", icon: "magnifyingglass")
                }
                .buttonStyle(.plain)
            }
            
            if results.isEmpty {
                Text("No results found")
            }
        }
        .onAppear {
            feedItems = [
                MeetFeedItem(meet: MeetEvent(name: "Test Meet", link: "Body body body"),
                             namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.text("Hello World"),
                              namespace: namespace, feedModel: $feedModel),
                MediaFeedItem(media: Media.video(VideoPlayer(player: nil)),
                              namespace: namespace, feedModel: $feedModel)]
            feedModel.selectedItem = feedItems[0].id
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
            ForEach($feedItems) { item in
                if item.id == feedModel.selectedItem {
                    AnyView(item.expandedView.wrappedValue)
                }
            }
        }
    }
    
    var results: [FeedItem] {
        if text.isEmpty {
            return feedItems
        } else {
            //THIS IS WHERE FILTRATION HAPPENS
            return feedItems
        }
    }
    
    var suggestions: [Suggestion] {
        if text.isEmpty {
            return suggestionsData
        } else {
            return suggestionsData.filter { $0.text.contains(text) }
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
