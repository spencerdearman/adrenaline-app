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
    @Environment(\.videoStore) var videoStore
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var mediaItems: [PostMediaItem] = []
    @State private var videoData: [String: Data] = [:]
    @State private var imageData: [String: Data] = [:]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var buttonPressed: Bool = false
    @AppStorage("email") private var email: String = ""
    
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
    
    var body: some View {
        NavigationView {
                VStack {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(6, reservesSpace: true)
                    
                    let size: CGFloat = 125
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.fixed(size)), GridItem(.fixed(size)), GridItem(.fixed(size))]) {
                            ForEach(mediaItems) { item in
                                AnyView(item.view
                                    .frame(width: size, height: size))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    
                    Spacer()
                    
                    HStack {
                        PhotosPicker(selection: $selectedItems) {
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
                        }
                        
                        Button {
                            Task {
                                buttonPressed = true
                                
                                if let user = try await getUserByEmail(email: email) {
                                    let post = try await createPost(user: user, title: title,
                                                                    description: description,
                                                                    videosData: videoData,
                                                                    imagesData: imageData)
                                    
                                    let (_, _) = try await savePost(user: user, post: post)
                                }
                                
                                didDismiss()
                                
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
        .onChange(of: selectedItems) { _ in
            clearMediaItems()
            
            for selectedItem in selectedItems {
                var selectedFileData: Data? = nil
            
                Task {
                    if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                        selectedFileData = data
                    }
                    
                    guard let type = selectedItem.supportedContentTypes.first else {
                        return
                    }
                    
                    if let data = selectedFileData,
                       type.conforms(to: UTType.movie) {
                        // Bypass saving to the cloud and locally store
                        // Note: will need to save to cloud and cache when
                        //       post is confirmed
                        let name = UUID().uuidString
                        guard let url = videoStore.saveVideo(data: data, email: email, name: name) else { return }
                        let video = VideoPlayer(player: AVPlayer(url: url))
                        
                        // Store Data and URL where data is saved in case it
                        // needs deleted
                        videoData[name] = data
                        mediaItems.append(PostMediaItem(data: PostMedia.video(video)))
                    } else if let data = selectedFileData,
                              type.conforms(to: UTType.image) {
                        guard let uiImage = UIImage(data: data) else { return }
                        let image = Image(uiImage: uiImage).resizable()
                        
                        let name = UUID().uuidString
                        imageData[name] = data
                        mediaItems.append(PostMediaItem(data: PostMedia.image(image)))
                    }
                }
            }
        }
    }
}
