//
//  MessageRow.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 9/2/23.
//

import SwiftUI

struct MessageRow: View {

    let message: Message
    let b: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(message.body)
                .font(.body)
                .padding(10)
        }
        .background(b ? .thinMaterial : .ultraThick)
        .cornerRadius(30)
    }
}

//struct MessageRow_Previews: PreviewProvider {
//    static var previews: some View {
//        MessageRow(message: Message(body: "Hello!", creationDate: .now()))
//    }
//}
