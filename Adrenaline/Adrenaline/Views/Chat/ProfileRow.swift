//
//  ProfileRow.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/7/23.
//

import SwiftUI

import SwiftUI

struct ProfileRow: View {
    var user: NewUser
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image("defaultImage")
                .resizable()
                .frame(width: 36, height: 36)
                .mask(Circle())
                .padding(12)
                .background(Color(UIColor.systemBackground).opacity(0.3))
                .mask(Circle())
                .overlay(CircularView(value: 100))
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
