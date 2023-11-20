//
//  UploadingPostView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/19/23.
//

import SwiftUI

struct UploadingPostView: View {
    @Binding var uploadingPost: Post?
    @Binding var uploadingProgress: Double
    @Binding var uploadFailed: Bool
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            ZStack {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20.0,
                                                          bottomLeading: 0.0,
                                                          bottomTrailing: 0.0,
                                                          topTrailing: 20.0),
                                       style: .continuous)
                    .fill(.thinMaterial)
                    .shadow(color: Color(red: 0.27, green: 0.17, blue: 0.49).opacity(0.15),
                            radius: 15, x: 0, y: 30)
                
                // Show upload failure message
                if uploadFailed {
                    HStack {
                        Text("Failed to upload post")
                            .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding([.leading, .trailing])
                } else {
                    HStack {
                        Text("Uploading Post...")
                            .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding([.leading, .trailing])
                }
            }
            .overlay(alignment: .bottomLeading) {
                if uploadFailed {
                    Rectangle()
                        .frame(width: screenWidth, height: 3)
                        .foregroundColor(.red)
                } else {
                    Rectangle()
                        .frame(width: uploadingProgress == 0.0
                               ? screenWidth * 0.02
                               : screenWidth * uploadingProgress,
                               height: 3)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(height: 70)
    }
}
