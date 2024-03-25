//
//  DeepLinkView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 3/24/24.
//

import SwiftUI

private enum DeepLink: Equatable {
    case profile(userId: String)
    case post(postId: String)
    
    static func ==(lhs: DeepLink, rhs: DeepLink) -> Bool {
        print("enum equatable", lhs, rhs)
        switch (lhs, rhs) {
            case (.profile(let lhsId), .profile(let rhsId)):
                return lhsId == rhsId
            case (.post(let lhsId), .post(let rhsId)):
                return lhsId == rhsId
            default:
                return false
        }
    }
}

struct DeepLinkView: View {
    @State private var user: NewUser? = nil
    @Binding var showDeepLink: Bool
    @Binding var link: URL?
    
    private let screenHeight = UIScreen.main.bounds.height
    
    private var deepLink: DeepLink? {
        getDeepLink(link)
    }
    
    private func getDeepLink(_ link: URL?) -> DeepLink? {
        guard let link else { return nil }
        guard let host = link.host() else { return nil }
        
        if host.starts(with: "profile"),
           let queryParams = link.queryParameters,
           let id = queryParams["id"] {
            return .profile(userId: id)
        } else if host.starts(with: "post"),
                  let queryParams = link.queryParameters,
                  let id = queryParams["id"] {
            return .post(postId: id)
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            Group {
                switch deepLink {
                        // Selecting the right profile happens in onChange below
                    case .profile:
                        if let user {
                            AdrenalineProfileView(newUser: user)
                        }
                    case .post(let postId):
                        VStack {
                            Text("Post")
                            Text(postId)
                        }
                    default:
                        Text("Something went wrong. Please try again with a different link.")
                            .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay {
            Button {
                withAnimation(.closeCard) {
                    showDeepLink = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.secondary)
                    .background(.ultraThinMaterial)
                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: screenHeight, alignment: .topLeading)
        }
        .onChange(of: link, initial: true) {
            Task {
                if let deepLink = getDeepLink(link), case .profile(let userId) = deepLink {
                    user = try await queryAWSUserById(id: userId)
                }
            }
        }
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
