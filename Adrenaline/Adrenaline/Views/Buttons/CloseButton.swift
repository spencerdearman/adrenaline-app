//
//  CloseButton.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct CloseButton: View {
    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: 17, weight: .bold))
            .frame(width: 36, height: 36)
            .foregroundColor(.secondary)
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 14, opacity: 0.4)
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton()
    }
}
