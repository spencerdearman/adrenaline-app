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
    @AppStorage("email") private var email: String = ""
    
    private let screenHeight = UIScreen.main.bounds.height
    
    private var containsMedia: Bool {
        !mediaItems.isEmpty
    }
    
    // Removes media items from local variables and deletes locally stored files
    private func clearMediaItems() {
        mediaItems = []
        imageData = [:]
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = paths[0]
        
        for (name, _) in videoData {
            do {
                let url = path.appendingPathComponent("\(email)-\(name).mp4")
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Failed to remove data at URL")
            }
        }
        videoData = [:]
    }
    
    private func didDismiss() {
        clearMediaItems()
        dismiss()
    }
    
    private func getPostMediaItem(item: PhotosPickerItem) async -> PostMediaItem? {
        do {
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
                return try await PostMediaItem(id: id, data: PostMedia.image(imageFromVideo(url: url,
                                                                                            at: .zero)))
                
            } else if let data = selectedFileData,
                      type.conforms(to: UTType.image) {
                guard let uiImage = UIImage(data: data) else { return nil }
                let image = Image(uiImage: uiImage).resizable()
                
                let name = UUID().uuidString
                imageData[name] = data
                return PostMediaItem(id: name, data: PostMedia.image(image))
            }
        } catch {
            print("Failed to get PostMediaItem")
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
    
    var body: some View {
        NavigationView {
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
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                }
                
                TextField("Caption", text: $caption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(6, reservesSpace: true)
                
                HStack {
                    Text("Only visible to coaches")
                        .foregroundColor(.primary)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Custom.medBlue)
                        .opacity(isCoachesOnlyChecked ? 1.0 : 0.0)
                        .overlay(Circle()
                            .strokeBorder(Custom.medBlue, lineWidth: 1)
                            .fill(.clear))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isCoachesOnlyChecked.toggle()
                            }
                        }
                    
                    Spacer()
                }
                .font(.system(size: 20))
                
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
                                    
                                    let (_, _) = try await savePost(user: user, post: post)
                                    print("Saved Post")
                                } else {
                                    print("Could not get user with email \(email)")
                                }
                                
                                didDismiss()
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
                                .foregroundStyle(Color.gray))
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                    }
                    .disabled(buttonPressed)
                }
            }
            .padding()
            .navigationTitle("New Post")
        }
        .onChange(of: selectedItems) {
            clearMediaItems()
            
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
