//
//  ProfileImage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 2/28/23.
//

import SwiftUI

struct ProfileImage: View {
    @Environment(\.colorScheme) private var currentMode
    let imageUrlString: String
    
    init(diverID: String) {
        imageUrlString = "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(diverID).jpg"
    }
    
    init(profilePicURL: String) {
        imageUrlString = profilePicURL
    }

    var body: some View {
        
        if let imageUrl = URL(string: imageUrlString) {
            AsyncImage(url: imageUrl) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width:170, height:300)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.ultraThinMaterial, lineWidth: 15)
                        }
                        .shadow(radius: 7)
                } else if phase.error != nil {
                    Image("defaultImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width:200, height:300)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white, lineWidth: 4)
                        }
                        .shadow(radius: 7)
                } else {
                    ProgressView()
                }
            }
        } else {
            Image("defaultImage")
                .resizable()
                .scaledToFit()
                .frame(width:200, height:300)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.white, lineWidth: 4)
                }
                .shadow(radius: 7)
        }
    }
}

struct MiniProfileImage: View {
    @Environment(\.colorScheme) var currentMode
    let imageUrlString: String
    var width: CGFloat
    var height: CGFloat
    
    init(diverID: String, width: CGFloat = 100, height: CGFloat = 150) {
        imageUrlString = "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(diverID).jpg"
        self.width = width
        self.height = height
    }
    
    init(profilePicURL: String, width: CGFloat = 100, height: CGFloat = 150) {
        imageUrlString = profilePicURL
        self.width = width
        self.height = height
    }
    
    var body: some View {
        let imageUrl = URL(string: imageUrlString)
        AsyncImage(url: imageUrl) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 4)
                    }
                    .shadow(radius: 7)
            } else if phase.error != nil {
                Image("defaultImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 4)
                    }
                    .shadow(radius: 7)
                
            } else {
                ProgressView()
            }
        }

    }
}
