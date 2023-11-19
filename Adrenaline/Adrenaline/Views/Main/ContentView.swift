//
//  ContentView.swift
//  DiveMeets
//
//  Created by Logan Sherwin on 3/1/23.
//

import SwiftUI
import Amplify
import Authenticator
import AVKit

// Global timeoutInterval to use for online loading pages
let timeoutInterval: TimeInterval = 30

// Global lock/delay on meet parser to allow time for SwiftUIWebView to access network
// (DiveMeetsConnectorView)
var blockingNetwork: Bool = false

struct ContentView: View {
    @EnvironmentObject var appLogic: AppLogic
    @Environment(\.colorScheme) var currentMode
    @Environment(\.scenePhase) var scenePhase
    @State private var tabBarState: Visibility = .visible
    @AppStorage("signupCompleted") var signupCompleted: Bool = false
    @AppStorage("email") var email: String = ""
    @AppStorage("authUserId") var authUserId: String = ""
    @State private var showAccount: Bool = false
    @State private var diveMeetsID: String = ""
    @State private var newUser: NewUser? = nil
    @State private var recentSearches: [SearchItem] = []
    @State private var uploadingPost: Post? = nil
    @State private var uploadingProgress: Double = 0.0
    @State private var uploadFailed: Bool = false
    private let splashDuration: CGFloat = 2
    private let moveSeparation: CGFloat = 0.15
    private let delayToTop: CGFloat = 0.5
    
    // Find the key window from connected scenes
    var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
    
    var hasHomeButton: Bool {
        if #available(iOS 13.0, *) {
            guard let window = keyWindow else { return false }
            return !(window.safeAreaInsets.top > 20)
        }
    }
    
    var menuBarOffset: CGFloat {
        hasHomeButton ? 0 : 20
    }
    
    var uploadingPostOffset: CGFloat {
        guard let window = keyWindow else { return 34.0 + menuBarOffset - 5.0 }
        return window.safeAreaInsets.bottom + menuBarOffset - 5.0
    }
    
    private func getCurrentUser() async -> NewUser? {
        let idPredicate = NewUser.keys.id == authUserId
        let users = await queryAWSUsers(where: idPredicate)
        if users.count == 1 {
            return users[0]
        } else {
            print("Failed to get NewUser")
        }
        
        return nil
    }
    
    // Retries getting the current user five times in case the user's
    // NewUser hasn't appeared in the DataStore yet. It then gets the user's diveMeetsID and adds
    // the current device to its list of tokens if not already added.
    //
    // This only seems to require retries on a fresh app launch, since the NewUser table should
    // never be missing their current user in subsequent app launches.
    private func getDataStoreData(numAttempts: Int = 0) async {
        if numAttempts == 5 { return }
        do {
            // Waits with exponential backoff to give DataStore time to update
            try await Task.sleep(seconds: pow(Double(numAttempts), 2))
            guard let user = await getCurrentUser() else {
                print("Failed attempt \(numAttempts + 1) getting DataStore data, retrying...")
                return await getDataStoreData(numAttempts: numAttempts + 1)
            }
            
            newUser = user
            diveMeetsID = user.diveMeetsID ?? ""
            
            // Adds device token to user's list of tokens for push notifications
            guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
            if !user.tokens.contains(token) {
                user.tokens.append(token)
                print("Tokens:", user.tokens)
                newUser = try await saveToDataStore(object: user)
            }
        } catch {
            print("Sleep failed")
        }
    }
    
    var body: some View {
        ZStack {
            if appLogic.initialized {
                Authenticator(
                    signInContent: { state in
                        NewSignIn(state: state, email: $email, authUserId: $authUserId,
                                  signupCompleted: $signupCompleted)
                    }, signUpContent: { state in
                        SignUp(state: state, email: $email, signupCompleted: $signupCompleted)
                    }, confirmSignUpContent: { state in
                        ConfirmSignUp(state: state)
                    }, resetPasswordContent: { state in
                        ForgotPassword(state: state)
                    }, confirmResetPasswordContent: { state in
                        ConfirmPasswordReset(state: state, signupCompleted: $signupCompleted)
                    }
                ) { state in
                    if !signupCompleted {
                        NewSignupSequence(signupCompleted: $signupCompleted, email: $email)
                            .onAppear {
                                Task {
                                    authUserId = state.user.userId
                                    try await Amplify.DataStore.clear()
                                }
                            }
                    } else {
                        ZStack(alignment: .bottom) {
                            TabView {
                                FeedBase(diveMeetsID: $diveMeetsID, showAccount: $showAccount,
                                         recentSearches: $recentSearches, uploadingPost: $uploadingPost)
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }
                                
                                if let user = newUser, user.accountType != "Spectator" {
                                    ChatView(diveMeetsID: $diveMeetsID, showAccount: $showAccount,
                                             recentSearches: $recentSearches,
                                             uploadingPost: $uploadingPost)
                                    .tabItem {
                                        Label("Chat", systemImage: "message")
                                    }
                                }
                                
                                RankingsView(diveMeetsID: $diveMeetsID, tabBarState: $tabBarState,
                                             showAccount: $showAccount, recentSearches: $recentSearches,
                                             uploadingPost: $uploadingPost)
                                .tabItem {
                                    Label("Rankings", systemImage: "trophy")
                                }
                                
                                Home()
                                    .tabItem {
                                        Label("Meets", systemImage: "figure.pool.swim")
                                    }
                            }
                            
                            if uploadingPost != nil {
                                UploadingPostView(uploadingPost: $uploadingPost, 
                                                  uploadingProgress: $uploadingProgress, 
                                                  uploadFailed: $uploadFailed)
                                    .offset(y: -uploadingPostOffset)
                            }
                        }
                        .fullScreenCover(isPresented: $showAccount, content: {
                            NavigationView {
                                // Need to use WrapperView here since we have to pass in state
                                // and showAccount for popover profile
                                if let user = newUser, user.accountType != "Spectator" {
                                    AdrenalineProfileWrapperView(state: state, newUser: user,
                                                                 showAccount: $showAccount,
                                                                 recentSearches: $recentSearches)
                                } else if let _ = newUser {
                                    SettingsView(state: state, newUser: newUser,
                                                 showAccount: $showAccount)
                                } else {
                                    // In the event that a NewUser can't be queried, this is the
                                    // default view
                                    AdrenalineProfileWrapperView(state: state,
                                                                 authUserId: authUserId,
                                                                 showAccount: $showAccount,
                                                                 recentSearches: $recentSearches)
                                }
                            }
                        })
                        .onChange(of: uploadingPost) {
                            if let user = newUser, let post = uploadingPost {
                                Task {
                                    uploadFailed = false
                                    uploadingProgress = 0.0
                                    guard let postVideos = post.videos else { return }
                                    try await postVideos.fetch()
                                    try await post.images?.fetch()
                                    
                                    let videos = postVideos.elements
                                    let images = post.images?.elements ?? []
                                    
                                    // Be aware of data races with uploadingProgress
                                    if try await trackUploadProgress(email: email,
                                                                     videos: videos,
                                                                     completedUploads: images.count,
                                                                     totalUploads: videos.count + images.count,
                                                                     uploadingProgress: $uploadingProgress) {
                                        print("Upload completed, saving post...")
                                        let (savedUser, _) = try await savePost(user: user, post: post)
                                        newUser = savedUser
                                    } else {
                                        // Display upload failure view
                                        uploadFailed = true
                                        
                                        // Remove successful videos from S3
                                        for video in videos {
                                            // This removal will trigger a lambda function that 
                                            // removes the streams from the streams bucket
                                            do {
                                                try await removeVideoFromS3(email: user.email, 
                                                                            videoId: video.id)
                                            } catch {
                                                print("Failed to remove \(video.id)")
                                            }
                                            
                                        }
                                        
                                        // Remove uploaded images from S3
                                        for image in images {
                                            do {
                                                try await removeImageFromS3(email: user.email, 
                                                                            imageId: image.id)
                                            } catch {
                                                print("Failed to remove \(image.id)")
                                            }
                                        }
                                        
                                    }
                                    
                                    // Sleep to show completed overlay before hiding
                                    try await Task.sleep(seconds: 2.0)
                                    withAnimation(.easeOut) {
                                        uploadingPost = nil
                                    }
                                }
                            }
                        }
                        .onAppear {
                            Task {
                                await getDataStoreData()
                            }
                        }
                        .ignoresSafeArea(.keyboard)
                    }
                }
            } else {
                Text("Loading")
            }
        }
    }
}
