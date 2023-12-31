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
    @State private var newUser: NewUser? = nil
    @State private var recentSearches: [SearchItem] = []
    @State private var uploadingPost: Post? = nil
    @State private var uploadingProgress: Double = 0.0
    @State private var uploadFailed: Bool = false
    @State private var updateDataStoreData: Bool = false
    // DataStore doesn't seem to update on deletion right away (Amplify bug), so keeping track of
    // deleted users so we can hide them until the app is restarted
    @State private var deletedChatIds = Set<String>()
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
            guard var user = await getCurrentUser() else {
                print("Failed attempt \(numAttempts + 1) getting DataStore data, retrying...")
                return await getDataStoreData(numAttempts: numAttempts + 1)
            }
            
            newUser = user
            
            // Adds device token to user's list of tokens for push notifications
            guard let token = UserDefaults.standard.string(forKey: "userToken") else { return }
            if !user.tokens.contains(token) {
                user.tokens.append(token)
                newUser = try await saveToDataStore(object: user)
            }
        } catch {
            print("Sleep failed")
        }
    }
    
    private func handleUploadFailure(email: String, videos: [Video], images: [NewImage]) async {
        // Display upload failure view
        uploadFailed = true
        
        // Remove successful videos from S3
        for video in videos {
            // This removal will trigger a lambda function that
            // removes the streams from the streams bucket
            do {
                try await removeVideoFromS3(email: email,
                                            videoId: video.id)
            } catch {
                print("Failed to remove \(video.id) from S3")
            }
            
        }
        
        // Remove uploaded images from S3
        for image in images {
            do {
                try await removeImageFromS3(email: email,
                                            imageId: image.id)
            } catch {
                print("Failed to remove \(image.id) from S3")
            }
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
                        // This view appears between the time the user is deleted and the sign out
                        // happens in state
                        // Note: email will be empty string here since account deletion clears it
                        //       from UserDefaults
                    } else if email == "" {
                        VStack {
                            Text("Signing out...")
                                .font(.largeTitle)
                            ProgressView()
                        }
                    } else {
                        ZStack(alignment: .bottom) {
                            TabView {
                                FeedBase(newUser: $newUser, showAccount: $showAccount,
                                         recentSearches: $recentSearches, uploadingPost: $uploadingPost)
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }
                                
                                if let user = newUser, user.accountType != "Spectator" {
                                    ChatView(newUser: $newUser, showAccount: $showAccount,
                                             recentSearches: $recentSearches,
                                             deletedChatIds: $deletedChatIds)
                                    .tabItem {
                                        Label("Chat", systemImage: "message")
                                    }
                                }
                                
                                RankingsView(newUser: $newUser, tabBarState: $tabBarState,
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
                                                                 recentSearches: $recentSearches,
                                                                 updateDataStoreData: $updateDataStoreData)
                                } else if let _ = newUser {
                                    SettingsView(state: state, 
                                                 newUser: newUser,
                                                 showAccount: $showAccount,
                                                 updateDataStoreData: $updateDataStoreData)
                                } else {
                                    // In the event that a NewUser can't be queried, this is the
                                    // default view
                                    AdrenalineProfileWrapperView(state: state,
                                                                 authUserId: authUserId,
                                                                 showAccount: $showAccount,
                                                                 recentSearches: $recentSearches,
                                                                 updateDataStoreData: $updateDataStoreData)
                                }
                            }
                        })
                        .onChange(of: uploadingPost) {
                            if let user = newUser, let post = uploadingPost {
                                Task {
                                    var videos: [Video] = []
                                    var images: [NewImage] = []
                                    
                                    do {
                                        uploadFailed = false
                                        uploadingProgress = 0.0
                                        
                                        try await post.videos?.fetch()
                                        try await post.images?.fetch()
                                        
                                        if let vids = post.videos {
                                            videos = vids.elements
                                        }
                                        
                                        if let imgs = post.images {
                                            images = imgs.elements
                                        }
                                        
                                        do {
                                            // Increase maximum wait time for uploads to account for content
                                            // moderation based on longest uploaded video
                                            let baseWaitTimeSeconds: Double = 45.0
                                            var maxWaitTimeSeconds: Double = 0.0
                                            for video in videos {
                                                let durationSeconds = try await getVideoDurationSeconds(
                                                    url: getVideoPathURL(email: user.email, name: video.id))
                                                
                                                // Add 30s of wait time for every 1 minute of video
                                                let waitTimeIncrease = durationSeconds / 2
                                                
                                                // Take max of current max wait time
                                                maxWaitTimeSeconds = max(maxWaitTimeSeconds,
                                                                         baseWaitTimeSeconds + waitTimeIncrease)
                                            }
                                            
                                            // Be aware of data races with uploadingProgress
                                            if try await trackUploadProgress(email: email,
                                                                             videos: videos,
                                                                             completedUploads: images.count,
                                                                             totalUploads: videos.count + images.count,
                                                                             uploadingProgress: $uploadingProgress,
                                                                             maxWaitTimeSeconds: maxWaitTimeSeconds) {
                                                
                                                let (savedUser, _) = try await savePost(user: user, post: post)
                                                newUser = savedUser
                                            } else {
                                                await handleUploadFailure(email: user.email,
                                                                          videos: videos,
                                                                          images: images)
                                            }
                                        } catch {
                                            print("Processing threw exception")
                                            print("\(error)")
                                            await handleUploadFailure(email: user.email,
                                                                      videos: videos,
                                                                      images: images)
                                        }
                                    } catch {
                                        print("Unable to get videos or images, skipping processing")
                                        print("\(error)")
                                        await handleUploadFailure(email: user.email,
                                                                  videos: videos,
                                                                  images: images)
                                    }
                                    
                                    // Remove local videos at this stage since we need them to check
                                    // video duration
                                    removeLocalVideos(email: user.email,
                                                      videoIds: videos.map { $0.id })
                                    
                                    // Sleep to show completed overlay before hiding
                                    try await Task.sleep(seconds: 2.0)
                                    
                                    withAnimation(.easeOut) {
                                        uploadingPost = nil
                                    }
                                }
                            }
                        }
                        .onChange(of: updateDataStoreData) {
                            if updateDataStoreData {
                                Task {
                                    await getDataStoreData()
                                    updateDataStoreData = false
                                }
                            }
                        }
                        .onAppear {
                            Task {
                                recentSearches = []
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
