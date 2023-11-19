//
//  UploadingPostView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 11/19/23.
//

import SwiftUI

struct UploadingPostView: View {
    @State private var percentComplete: CGFloat = 0.5
    @Binding var uploadingPost: Post?
    
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
                
                HStack {
                    Image(systemName: "gearshape")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .padding([.top, .bottom])
                    Text("Uploading Post...")
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding([.leading, .trailing])
            }
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .frame(width: screenWidth * percentComplete, height: 3)
                .foregroundColor(.accentColor)
            }
        }
        .frame(height: 70)
    }
}
