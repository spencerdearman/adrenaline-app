//
//  FeedBase.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI
import UIKit
import AVKit
import Contacts

struct FeedBase: View {
    @Environment(\.colorScheme) var currentMode
    @Namespace var namespace
    @Binding var newUser: NewUser?
    @Binding var showAccount: Bool
    @Binding var recentSearches: [SearchItem]
    @Binding var uploadingPost: Post?
    // Only used to satisfy NavigationBar binding, otherwise unused
    @State private var feedModel: FeedModel = FeedModel()
    @State private var showStatusBar = true
    @State private var contentHasScrolled = false
    @State private var feedItems: [FeedItem] = []
    @State private var feedItemsLoaded: Bool = false
    @State private var tabBarState: Visibility = .visible
    @State private var contacts: [CNContact] = []
    @State private var suggestedUsers: [NewUser] = []
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        NavigationView {
            ZStack {
                (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
                Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                    .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
                
                ScrollView {
                    // Scrolling Detection
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
                    }
                    .onPreferenceChange(ScrollPreferenceKey.self) { value in
                        withAnimation(.easeInOut) {
                            if value < 0 {
                                contentHasScrolled = true
                                tabBarState = .hidden
                            } else {
                                contentHasScrolled = false
                                tabBarState = .visible
                            }
                        }
                    }
                    
                    Rectangle()
                        .frame(width: 100, height: screenHeight * 0.15)
                        .opacity(0)
                    
                    if feedItemsLoaded {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach($feedItems) { item in
                                AnyView(item.collapsedView.wrappedValue)
                            }
                            
                            if suggestedUsers.count > 0 {
                                suggestedUsersView
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: -80)
                    } else {
                        VStack {
                            Text("Getting new posts")
                                .foregroundColor(.secondary)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            ProgressView()
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .modifier(OutlineOverlay(cornerRadius: 30))
                        .backgroundStyle(cornerRadius: 30)
                        .padding(20)
                        .padding(.vertical, 80)
                        .offset(y: 50)
                    }
                }
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .coordinateSpace(name: "scroll")
            }
            .overlay {
                NavigationBar(title: "Adrenaline", newUser: $newUser,
                              showAccount: $showAccount, contentHasScrolled: $contentHasScrolled,
                              feedModel: $feedModel, recentSearches: $recentSearches,
                              uploadingPost: $uploadingPost)
                .frame(width: screenWidth)
            }
        }
        .onChange(of: newUser, initial: true) {
            Task {
                if let user = newUser {
                    // Gets current user's favorites' posts
                    let favorites = user.favoritesIds
                    let posts = try await getFeedPostsByUserIds(ids: favorites)
                    //                    print("Posts", posts)
                    
                    // Gets current user's posts (DEV)
                    //                    try await user.posts?.fetch()
                    //                    guard let posts = user.posts?.elements else { return }
                    
                    feedItems = try await posts.concurrentMap { post in
                        try await PostFeedItem(user: user, post: post, namespace: namespace)
                    }
                    feedItemsLoaded = true
                }
            }
        }
        .onChange(of: contacts) {
            Task {
                suggestedUsers = try await getSuggestedUsers(contacts: contacts)
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .userInteractive).async {
                getContactList()
            }
        }
        .statusBar(hidden: !showStatusBar)
    }
    
    var suggestedUsersView: some View {
        VStack {
            HStack {
                Text("People you may know")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(suggestedUsers, id: \.id) { user in
                        NavigationLink {
                            AdrenalineProfileView(newUser: user)
                        } label: {
                            VStack {
                                MiniProfileImage(profilePicURL: getProfilePictureURL(userId: user.id))
                                Text(user.firstName + " " + user.lastName)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(20)
                            .background(.white)
                            .modifier(OutlineOverlay(cornerRadius: 30))
                            .backgroundStyle(cornerRadius: 30)
                            .padding(.vertical, 10)
                            .shadow(radius: 5)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .frame(width: screenWidth * 0.9)
        .background(.ultraThinMaterial)
        .modifier(OutlineOverlay(cornerRadius: 30))
        .backgroundStyle(cornerRadius: 30)
    }
    
    // https://medium.com/@sarankumaresh1/fetch-contact-list-view-in-swiftui-6f72fb6e6146
    private func getContactList() {
        let CNStore = CNContactStore()
        switch CNContactStore.authorizationStatus (for: .contacts) {
            case .authorized:
                do {
                    let keys = [CNContactGivenNameKey as CNKeyDescriptor,
                                CNContactFamilyNameKey as CNKeyDescriptor,
                                CNContactEmailAddressesKey as CNKeyDescriptor,
                                CNContactPhoneNumbersKey as CNKeyDescriptor]
                    let request = CNContactFetchRequest (keysToFetch: keys)
                    try CNStore.enumerateContacts(with: request, usingBlock: { contact, _ in
                        contacts.append(contact)
                    })
                } catch {
                    print("Error on contact fetching \(error)")
                }
            case .denied:
                print("denied")
            case .notDetermined:
                print("notDetermined")
                CNStore.requestAccess(for: .contacts) { granted, error in
                    if granted {
                        getContactList()
                    } else if let error = error {
                        print("Error requesting contact access: \(error)")
                    }
                }
            case .restricted:
                print("restricted")
            @unknown default:
                print("")
        }
    }
    
    private func getSuggestedUsers(contacts: [CNContact]) async throws -> [NewUser] {
        var result: [NewUser] = []
        var seenIds = Set<String>()
        let newUsers: [NewUser] = try await query()
        var emails: [String: NewUser] = [:]
        var names: [String: NewUser] = [:]
        var phoneNumbers: [String: NewUser] = [:]
        
        for user in newUsers {
            emails[user.email] = user
            let nameKey = (user.firstName + user.lastName).replacingOccurrences(of: " ", with: "")
            names[nameKey] = user
            if let key = user.phone {
                phoneNumbers[key] = user
            }
        }
        
        for contact in contacts {
            let contactEmails = Set(contact.emailAddresses.map { String($0.value) })
            let contactPhoneNumbers = Set(contact.phoneNumbers.map { $0.value.stringValue })
            let contactNameKey = (contact.givenName + contact.familyName).replacingOccurrences(of: " ", with: "")
            let maxEditDistance = Int(trunc(Double(contactNameKey.count) * 0.3))
            
            let matchingEmails = Set(contactEmails).intersection(emails.keys)
            let matchingPhoneNumbers = Set(contactPhoneNumbers).intersection(phoneNumbers.keys)
            
            if matchingEmails.count > 0 {
                result += matchingEmails.reduce(into: [NewUser]()) { acc, email in
                    if let user = emails[email], !seenIds.contains(user.id) {
                        acc.append(user)
                        seenIds.insert(user.id)
                    }
                }
            }
            
            for key in names.keys {
                // Succeeds if names are 70% the same
                if contactNameKey.levenshteinDistance(to: key) <= maxEditDistance,
                   let user = names[key], !seenIds.contains(user.id) {
                    result.append(user)
                    seenIds.insert(user.id)
                }
            }
            
            if matchingPhoneNumbers.count > 0 {
                result += matchingPhoneNumbers.reduce(into: [NewUser]()) { acc, phoneNumber in
                    if let user = phoneNumbers[phoneNumber], !seenIds.contains(user.id) {
                        acc.append(user)
                        seenIds.insert(user.id)
                    }
                }
            }
        }
        
        return result
    }
}

struct CloseButtonWithFeedModel: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var feedModel: FeedModel
    
    var body: some View {
        Button {
            feedModel.isAnimated ?
            withAnimation(.closeCard) {
                feedModel.showTile = false
                feedModel.selectedItem = ""
            }
            : presentationMode.wrappedValue.dismiss()
        } label: {
            CloseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(20)
        .padding(.top, 60)
        .ignoresSafeArea()
    }
}

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}

// https://stackoverflow.com/a/66583418
extension String {
    
    func levenshteinDistance(to string: String, ignoreCase: Bool = true,
                             trimWhiteSpacesAndNewLines: Bool = true) -> Int {
        
        var firstString = self
        var secondString = string
        
        if ignoreCase {
            firstString = firstString.lowercased()
            secondString = secondString.lowercased()
        }
        
        if trimWhiteSpacesAndNewLines {
            firstString = firstString.trimmingCharacters(in: .whitespacesAndNewlines)
            secondString = secondString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let empty = [Int](repeating: 0, count: secondString.count)
        var last = [Int](0...secondString.count)
        
        for (i, tLett) in firstString.enumerated() {
            var cur = [i + 1] + empty
            for (j, sLett) in secondString.enumerated() {
                cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
            }
            
            last = cur
        }
        
        if let validDistance = last.last {
            return validDistance
        }
        
        assertionFailure()
        return 0
    }
}
