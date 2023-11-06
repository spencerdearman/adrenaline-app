//
//  SettingsPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/25/23.
//

import SwiftUI
import Authenticator

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var state: SignedInState
    @State var isPinned = false
    @State var isDeleted = false
    @Binding var showAccount: Bool
    
    var newUser: NewUser?
    
    init(state: SignedInState, newUser: NewUser?, showAccount: Binding<Bool> = .constant(false)) {
        self.state = state
        self.newUser = newUser
        self._showAccount = showAccount
    }
    
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
                        Text("\(newUser?.firstName ?? "") \(newUser?.lastName ?? "")")
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
                        UserDefaults.standard.removeObject(forKey: "authUserId")
                        
                        // Remove current device token from user
                        if let user = newUser {
                            guard let token = UserDefaults.standard.string(forKey: "userToken") else { print("Token not found"); return }
                            user.tokens = user.tokens.filter { $0 != token }
                            
                            let _ = try await saveToDataStore(object: user)
                            
                            // Sleep for one second to allow DataStore to sync before signing out
                            // and losing authorization
                            try await Task.sleep(seconds: 1)
                        } else {
                            print("user not found")
                        }
                        
                        await state.signOut()
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
            .toolbar {
                if newUser?.accountType == "Spectator" {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.closeCard) {
                                showAccount = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .bold))
                                .frame(width: 36, height: 36)
                                .foregroundColor(.secondary)
                                .background(.ultraThinMaterial)
                                .backgroundStyle(cornerRadius: 14, opacity: 0.4)
                        }
                    }
                }
            }
    }
}
