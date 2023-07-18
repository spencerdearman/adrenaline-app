//
//  FirstOpenView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

struct FirstOpenView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .frame(width: 250, height: 125)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 6)
                VStack {
                    Text("Welcome")
                        .font(.title)
                    .bold()
                    HStack {
                        NavigationLink(destination: ProfileView(profileLink: "")) {
                            Text("Login")
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(40)
                        .foregroundColor(.primary)
                        NavigationLink(destination: AccountTypeSelectView()) {
                            Text("Sign Up")
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(40)
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct FirstOpenView_Previews: PreviewProvider {
    static var previews: some View {
        FirstOpenView()
    }
}
