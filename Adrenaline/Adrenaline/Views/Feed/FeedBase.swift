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
    @State private var feedItems: [PostFeedItem] = []
    @State private var feedItemsLoaded: Bool = false
    @State private var tabBarState: Visibility = .visible
    @State private var contacts: [CNContact] = []
    @State private var suggestedUsers: [NewUser] = []
    @State private var contactsRefreshed: Bool = false
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    // Insert suggested users tile after below number of posts have been shown
    private let insertSuggestedUsersSlot = 10
    var columns = [GridItem(.adaptive(minimum: 300), spacing: 20)]
    
    var body: some View {
        NavigationView {
            ZStack {
                (currentMode == .light ? Color.white : Color.black).ignoresSafeArea()
                Image(currentMode == .light ? "FeedBackgroundLight" : "FeedBackgroundDark")
                    .offset(x: screenWidth * 0.27, y: -screenHeight * 0.02)
                
                GeometryReader { geometry in
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
                                // Show suggested users at the top if feed items is empty
                                if feedItems.count == 0, suggestedUsers.count > 0 {
                                    suggestedUsersView
                                } else {
                                    // Show feed items and insert suggested users at the bottom or after
                                    // the insertSuggestedUsersSlot-th post is shown
                                    ForEach($feedItems) { item in
                                        AnyView(item.collapsedView.wrappedValue)
                                        
                                        // Check if should show suggested users under this post
                                        if suggestedUsers.count > 0 &&
                                            shouldShowSuggestedUsers(items: feedItems,
                                                                     currentItem: item.wrappedValue) {
                                            suggestedUsersView
                                        }
                                    }
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
                    // Get contact list of current device
                    DispatchQueue.global(qos: .userInteractive).async {
                        getContactList()
                    }
                    
                    // Gets current user's favorites' posts
                    let favorites = user.favoritesIds
                    let posts = try await getFeedPostsByUserIds(ids: favorites)
                    
                    // Gets current user's posts (DEV)
//                    try await user.posts?.fetch()
//                    guard let posts = user.posts?.elements else { return }
                    
                    feedItems = try await posts.concurrentMap { user, post in
                        try await PostFeedItem(user: user, post: post, namespace: namespace)
                    }
                    feedItemsLoaded = true
                }
            }
        }
        .onChange(of: contactsRefreshed) {
            if contactsRefreshed {
                Task {
                    suggestedUsers = try await getSuggestedUsers(contacts: contacts)
                    contactsRefreshed = false
                }
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
                HStack(spacing: 10) {
                    ForEach(suggestedUsers, id: \.id) { user in
                        NavigationLink {
                            AdrenalineProfileView(newUser: user)
                        } label: {
                            VStack {
                                MiniProfileImage(profilePicURL: getProfilePictureURL(userId: user.id),
                                                 width: 80, height: 80)
                                Text(user.firstName + " " + user.lastName)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 5)
                            }
                            .padding(20)
                            .frame(width: 150, height: 185)
                            .background(currentMode == .light ? .white : .black)
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
    
    // Returns true if the view should show the suggested users tile below the current item
    private func shouldShowSuggestedUsers(items: [FeedItem], currentItem: FeedItem) -> Bool {
        // If list has the same or more items than the suggested slot and the current item being
        // rendered is in that slot, then append suggested users
        if items.count >= insertSuggestedUsersSlot &&
            currentItem == items[insertSuggestedUsersSlot - 1] {
            return true
            // If list has the same or more items than the suggested slot, but the current item is
            // not in that slot, don't append suggested users
        } else if items.count >= insertSuggestedUsersSlot {
            return false
            // If the list has less items than the suggested slot, but it is rendering the last
            // item, append suggested users
        } else if currentItem == items[items.count - 1] {
            return true
        }
        
        return false
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
        
        contactsRefreshed = true
    }
    
    private func getSuggestedUsers(contacts: [CNContact]) async throws -> [NewUser] {
        var result: [NewUser] = []
        var seenIds = Set<String>()
        
        // Filter out current user and users that are already favorited by the current user
        guard let currentUser = newUser else { return [] }
        var currentUserFavorites = Set(currentUser.favoritesIds)
        currentUserFavorites.insert(currentUser.id)
        let newUsers: [NewUser] = try await query().filter { !currentUserFavorites.contains($0.id) }
            .sorted {
                if let first = $0.updatedAt, let second = $1.updatedAt {
                    return first > second
                } else {
                    return false
                }
            }
        
        var emails: [String: NewUser] = [:]
        var names: [String: NewUser] = [:]
        var phoneNumbers: [String: NewUser] = [:]
        
        // Builds dictionaries to pull users from
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
            
            // Appends users based on matching emails
            if matchingEmails.count > 0 {
                result += matchingEmails.reduce(into: [NewUser]()) { acc, email in
                    if let user = emails[email], !seenIds.contains(user.id) {
                        acc.append(user)
                        seenIds.insert(user.id)
                    }
                }
            }
            
            // Appends users based on similar names
            for key in names.keys {
                // Succeeds if names are 70% the same
                if contactNameKey.levenshteinDistance(to: key) <= maxEditDistance,
                   let user = names[key], !seenIds.contains(user.id) {
                    result.append(user)
                    seenIds.insert(user.id)
                }
            }
            
            // Appends users based on matching phone numbers
            if matchingPhoneNumbers.count > 0 {
                result += matchingPhoneNumbers.reduce(into: [NewUser]()) { acc, phoneNumber in
                    if let user = phoneNumbers[phoneNumber], !seenIds.contains(user.id) {
                        acc.append(user)
                        seenIds.insert(user.id)
                    }
                }
            }
        }
        
        // Appends up to five most recently updated users to suggest active users
        var count = 0
        let appendActiveUsers = 5
        for user in newUsers {
            if !seenIds.contains(user.id) {
                result.append(user)
                seenIds.insert(user.id)
                count += 1
            }
            
            if count == appendActiveUsers {
                break
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

struct OnScreenModifier: ViewModifier {
    var onAppear: () -> Void
    var onDisappear: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry -> Color in
                    let rect = geometry.frame(in: .global)
                    DispatchQueue.main.async {
                        if rect.maxY > 0 && rect.minY < UIScreen.main.bounds.height {
                            onAppear()
                        } else {
                            onDisappear()
                        }
                    }
                    return Color.clear
                }
            )
    }
}

extension View {
    func onScreenAppear(perform onAppear: @escaping () -> Void, onDisappear: @escaping () -> Void) -> some View {
        self.modifier(OnScreenModifier(onAppear: onAppear, onDisappear: onDisappear))
    }
}
