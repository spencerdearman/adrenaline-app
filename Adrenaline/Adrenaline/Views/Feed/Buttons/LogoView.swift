//
//  SearchButton.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/23/23.
//

import SwiftUI

struct LogoView: View {
    var imageName: String = ""
    
    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 26, height: 26)
            .cornerRadius(10)
            .padding(8)
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 18, opacity: 0.4)
    }
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        LogoView(imageName: "Spencer")
    }
}

