//
//  MessageRow.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI

struct MessageRow: View {

    let message: Message
    let currentUserIsSender: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(message.body)
                .foregroundColor(currentUserIsSender ? .white : .primary)
                .font(.body)
                .padding(10)
        }
        .background(currentUserIsSender ? .blue.opacity(0.7) : .gray.opacity(0.2))
        .cornerRadius(30)
    }
}
