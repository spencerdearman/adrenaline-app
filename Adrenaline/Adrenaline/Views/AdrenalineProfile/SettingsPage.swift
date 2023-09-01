//
//  SettingsPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/25/23.
//

import SwiftUI
import Authenticator

struct SettingsView: View {
    @State var isPinned = false
    @State var isDeleted = false
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var state: SignedInState
    
    var body: some View {
            List {
                Section {
                    VStack {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .symbolVariant(.circle.fill)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.blue, .blue.opacity(0.3), .red)
                            .font(.system(size: 32))
                            .padding()
                            .background(Circle().fill(.ultraThinMaterial))
                            .background(AnimatedBlobView(
                                colors: [.white, Custom.coolBlue])
                                .frame(width: 400, height: 414)
                                .offset(x: 200, y: 0)
                                .scaleEffect(0.8))
                            .background(AnimatedBlobView(
                                colors: [.white, Custom.lightBlue, Custom.coolBlue])
                                .frame(width: 400, height: 414)
                                .offset(x: -50, y: 200)
                                .scaleEffect(0.7))
                            .background(AnimatedBlobView(
                                colors: [.white, Custom.lightBlue, Custom.medBlue, Custom.coolBlue])
                                .frame(width: 400, height: 414)
                                .offset(x: -100, y: 20)
                                .scaleEffect(1.6)
                                .rotationEffect(Angle(degrees: 60)))
                        Text("Spencer Dearman")
                            .font(.title.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                Section {
                    NavigationLink {} label: {
                        Label("Profile", systemImage: "person")
                    }
                    
                    NavigationLink {} label: {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink {} label: {
                        Label("Billing", systemImage: "creditcard")
                    }
                    
                    NavigationLink {} label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }
                .listRowSeparator(.automatic)
                
                Section {
                    NavigationLink {} label: {
                        Label("DiveMeets", systemImage: "person")
                    }
                    NavigationLink {} label: {
                        Label("USA Diving", systemImage: "person")
                    }
                }
                
                Button {} label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
                .onTapGesture {
                    Task {
                        await state.signOut()
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
    }
}
//struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
