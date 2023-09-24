//
//  NewPostView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 9/23/23.
//

import SwiftUI

struct NewPostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @AppStorage("email") private var email: String = ""
    
    var body: some View {
        NavigationView {
                VStack {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(6, reservesSpace: true)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "camera")
                            .font(.system(size: 22, weight: .bold))
                            .frame(width: 48, height: 48)
                            .foregroundColor(.secondary)
                            .background(.ultraThinMaterial)
                            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        Button {
                            print("Gallery")
                        } label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22, weight: .bold))
                                .frame(width: 48, height: 48)
                                .foregroundColor(.secondary)
                                .background(.ultraThinMaterial)
                                .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                if let user = try await getUserByEmail(email: email) {
                                    let post = Post(title: title, description: description, newuserID: user.id)
                                    
                                    let (_, _) = try await savePost(user: user, post: post)
                                }
                                
                                dismiss()
                            }
                        } label: {
                            Text("Post")
                                .padding()
                                .font(.system(size: 22, weight: .bold))
                                .frame(height: 48)
                                .foregroundColor(.secondary)
                                .background(.ultraThinMaterial)
                                .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                    }
                }
                .padding()
                .navigationTitle("New Post")
        }
    }
}

#Preview {
    NewPostView()
}
