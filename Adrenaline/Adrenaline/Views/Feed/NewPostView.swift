//
//  NewPostView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/23/23.
//

import SwiftUI
import PhotosUI
import AVKit
import UIKit

struct NewPostView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) var dismiss
    @State private var caption: String = ""
    @State private var mediaItems: [PostMediaItem] = []
    @State private var videoData: [String: Data] = [:]
    @State private var imageData: [String: Data] = [:]
    @State private var idOrder: [String] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var buttonPressed: Bool = false
    @State private var postErrorMsg: String? = nil
    @State private var isLoadingMediaItems: Bool = false
    @State private var isCoachesOnlyChecked: Bool = false
    @FocusState private var captionFocused: Bool
    @AppStorage("email") private var email: String = ""
    @Binding var uploadingPost: Post?
    
    private let screenHeight = UIScreen.main.bounds.height
    private let screenWidth = UIScreen.main.bounds.width
    
    private var containsMedia: Bool {
        !mediaItems.isEmpty
    }
    
    private func getPostMediaItem(item: PhotosPickerItem) async -> PostMediaItem? {
        var selectedFileData: Data? = nil
        
        if let data = try? await item.loadTransferable(type: Data.self) {
            selectedFileData = data
        }
        
        guard let type = item.supportedContentTypes.first else {
            return nil
        }
        
        if let data = selectedFileData,
           type.conforms(to: UTType.movie) {
            // Bypass saving to the cloud and locally store
            // Note: will need to save to cloud and cache when
            //       post is confirmed
            let id = UUID().uuidString
            guard let url = await saveVideo(data: data, email: email, name: id) else {
                return nil
            }
            
            // Store Data and URL where data is saved in case it
            // needs deleted
            videoData[id] = data
            return PostMediaItem(id: id, data: PostMedia.localVideo(AVPlayer(url: url)),
                                 playVideoOnAppear: true, videoIsLooping: true)
            
        } else if let data = selectedFileData,
                  type.conforms(to: UTType.image) {
            guard let uiImage = UIImage(data: data) else { return nil }
            let image = Image(uiImage: uiImage).resizable()
            
            let name = UUID().uuidString
            imageData[name] = data
            return PostMediaItem(id: name, data: PostMedia.image(image))
        }
        
        return nil
    }
    
    // Concurrently loads picker items into PostMediaItems and maintains their order
    // https://stackoverflow.com/a/75709731/22068672
    private func loadMediaItems(_ pickerItems: [PhotosPickerItem]) async -> [PostMediaItem] {
        return await withTaskGroup(of: (Int, PostMediaItem?).self) { group in
            for (index, item) in pickerItems.enumerated() {
                group.addTask { await (index, getPostMediaItem(item: item))}
            }
            
            let dictionary = await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
            return pickerItems.indices.compactMap { dictionary[$0] }
        }
    }
    
    var aggressiveSpacing: some View {
        Group {
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use systemBackground to match background color of sheet
                // Need tappable view to break focus from caption
                Color(UIColor.systemBackground)
                    .onTapGesture {
                        captionFocused = false
                    }
                
                VStack {
                    if mediaItems.isEmpty, !isLoadingMediaItems {
                        PhotosPicker(selection: $selectedItems, selectionBehavior: .ordered) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 48, weight: .bold))
                                
                                Text("Add media to start creating a post")
                                    .padding(.top)
                            }
                            .padding()
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                    } else if isLoadingMediaItems {
                        ProgressView()
                            .padding(.vertical)
                    } else {
                        // https://www.appcoda.com/scrollview-paging/
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                ForEach(mediaItems) { item in
                                    AnyView(item.view)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                        .padding(.horizontal, 10)
                                        .containerRelativeFrame(.horizontal)
                                        .scrollTransition(.animated, axis: .horizontal) {
                                            content, phase in
                                            content
                                                .opacity(phase.isIdentity ? 1.0 : 0.8)
                                                .scaleEffect(phase.isIdentity ? 1.0 : 0.8)
                                        }
                                        .onAppear {
                                            if case let .localVideo(v) = item.data {
                                                v.seek(to: .zero)
                                                v.play()
                                            }
                                        }
                                }
                            }
                        }
                        .scrollTargetBehavior(.paging)
                    }
                    
                    VStack {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: screenHeight * 0.005)
                        HStack {
                            Spacer()
                            Text("Only visible to coaches")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isCoachesOnlyChecked.toggle()
                                }
                            } label: {
                                Image(systemName: "checkmark.shield")
                                    .opacity(isCoachesOnlyChecked ? 1.0 : 0.0)
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.secondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Custom.medBlue, lineWidth: 1.5)
                                    )
                                    .background(isCoachesOnlyChecked ? Color.blue.opacity(0.3) : Color.clear)
                                    .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                                    .scaleEffect(0.8)
                            }
                            aggressiveSpacing
                        }
                        
                        Divider()
                        
                        TextField("Caption", text: $caption, axis: .vertical)
                            .lineLimit(6, reservesSpace: true)
                            .frame(width: screenWidth * 0.85)
                            .focused($captionFocused)
                    }
                    .frame(maxWidth: .infinity)
                    .background (
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15),
                                    radius: 15, x: 0, y: 30)
                    )
                    
                    Spacer()
                    
                    HStack {
                        PhotosPicker(selection: $selectedItems, selectionBehavior: .ordered) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22, weight: .bold))
                                .frame(width: 48, height: 48)
                                .foregroundColor(.secondary)
                                .background(.ultraThinMaterial)
                                .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                        
                        Spacer()
                        
                        if buttonPressed {
                            ProgressView()
                                .padding(.trailing)
                        } else if let msg = postErrorMsg {
                            Text(msg)
                                .foregroundStyle(.red)
                        }
                        
                        Button {
                            Task {
                                do {
                                    buttonPressed = true
                                    
                                    // Break early if attempting to post without media
                                    if !containsMedia {
                                        postErrorMsg = "Post must have media"
                                        buttonPressed = false
                                        return
                                    } else {
                                        // Clears post error if press Post with media attached
                                        postErrorMsg = nil
                                    }
                                    
                                    if let user = try await getUserByEmail(email: email) {
                                        let post = try await createPost(user: user,
                                                                        caption: caption,
                                                                        videosData: videoData,
                                                                        imagesData: imageData,
                                                                        idOrder: idOrder,
                                                                        isCoachesOnly: isCoachesOnlyChecked)
                                        print("Created Post")
                                        
                                        // Saves to binding so it can be tracked while uploading
                                        uploadingPost = post
                                    } else {
                                        print("Could not get user with email \(email)")
                                    }
                                    
                                    dismiss()
                                } catch PostError.videoTooLong {
                                    print("Post creation failed, video is too long")
                                    postErrorMsg = "Failed to create post, videos must be under three minutes long"
                                } catch {
                                    print("\(error)")
                                    postErrorMsg = "Failed to create post, please try again"
                                    
                                }
                                
                                buttonPressed = false
                            }
                        } label: {
                            Text("Post")
                                .padding()
                                .font(.system(size: 22, weight: .bold))
                                .frame(height: 48)
                                .foregroundColor(currentMode == .light ? .white : .secondary)
                                .background(Rectangle()
                                    .foregroundStyle(containsMedia ? Custom.medBlue : Color.gray))
                                .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                        .disabled(buttonPressed)
                    }
                }
                .padding()
                .navigationTitle("New Post")
            }
        }
        .onChange(of: selectedItems) {
            // Remove local videos and manually clear locals after a change in selection
            removeLocalVideos(email: email, videoIds: Array(videoData.keys))
            videoData = [:]
            imageData = [:]
            mediaItems = []
            
            Task {
                isLoadingMediaItems = true
                
                mediaItems = await loadMediaItems(selectedItems)
                isLoadingMediaItems = false
                
                idOrder = mediaItems.map { $0.id }
                
                // Resets missing media post error if mediaItems gets updated with media
                if containsMedia {
                    postErrorMsg = nil
                }
            }
        }
    }
}
