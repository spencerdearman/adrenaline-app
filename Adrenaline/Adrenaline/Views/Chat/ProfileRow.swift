//
//  ProfileRow.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/7/23.
//

import SwiftUI
import CachedAsyncImage

struct ProfileRow: View {
    var user: NewUser
    @Binding var newMessages: Set<String>
    @State var newMessagesBool: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AnyView(
                user.diveMeetsID != nil
                ? AnyView(CachedAsyncImage(url: URL(string: "https://secure.meetcontrol.com/divemeets/system/profilephotos/\(user.diveMeetsID!).jpg?&x=511121484"),
                                           urlCache: .imageCache, 
                                           transaction: .init(animation: .easeOut)) { phase in
                                         switch phase {
                                             case .empty:
                                                 Color.white
                                             case .success(let image):
                                                 image.resizable()
                                             case .failure(_):
                                                Image("defaultImage").resizable()
                                             @unknown default:
                                                Image("defaultImage").resizable()
                                         }
                                     })
                : AnyView(Image("defaultImage").resizable())
            )
            .frame(width: 36, height: 36)
            .mask(Circle())
            .padding(12)
            .background(Color(UIColor.systemBackground).opacity(0.3))
            .mask(Circle())
            .onChange(of: newMessages) {
                newMessagesBool = newMessages.contains(user.id)
            }
            .overlay(CircularView(value: 100, newMessage: $newMessagesBool))
            VStack(alignment: .leading, spacing: 8) {
                Text(user.accountType)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(user.firstName) \(user.lastName)")
                    .fontWeight(.semibold)
                ProgressView(value: 1)
                    .accentColor(.white)
                    .frame(maxWidth: 132)
            }
            Spacer()
        }
    }
}
