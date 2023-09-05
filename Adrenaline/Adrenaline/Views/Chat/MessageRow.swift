//
//  MessageRow.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI

struct MessageRow: View {
    
    let message: Message
    let isCurrentUser: Bool
    
    private var iconName: String {
        if let initial = message.senderName.first {
            return initial.lowercased()
        } else {
            return "questionMark"
        }
    }
    
    private var iconColor: Color {
        if isCurrentUser {
            return .blue
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack(alignment: .top) {
                Image(systemName: "\(iconName).circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading) {
                    Text(message.senderName)
                        .font(.headline)
                    
                    Text(message.body)
                        .font(.body)
                }
            }
            .padding(.horizontal, 16)
            
            Divider().padding(.leading, 16)
        }
    }
}

//struct MessageRow_Previews: PreviewProvider {
//    static var previews: some View {
//        MessageRow()
//    }
//}
