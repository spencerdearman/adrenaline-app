//
//  SettingsPage.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 8/25/23.
//

import SwiftUI
import Authenticator
import Amplify

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var state: SignedInState
    @State private var isPinned = false
    @State private var isDeleted = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var selectedCollege: String = ""
    @AppStorage("authUserId") private var authUserId: String = ""
    @Binding var showAccount: Bool
    @Binding var updateDataStoreData: Bool
    @ScaledMetric private var linkButtonWidthScaled: CGFloat = 300
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    
    private var linkButtonWidth: CGFloat {
        min(linkButtonWidthScaled, screenWidth * 0.8)
    }
    
    var newUser: NewUser?
    
    init(state: SignedInState, newUser: NewUser?, showAccount: Binding<Bool> = .constant(false),
         updateDataStoreData: Binding<Bool>) {
        self.state = state
        self.newUser = newUser
        self._showAccount = showAccount
        self._updateDataStoreData = updateDataStoreData
    }
    
    // Clears Athlete skill ratings for newUser unlinking a DiveMeets account
    private func clearSkillRatings() async throws -> NewAthlete? {
        guard let user = newUser else { print("user nil"); return nil }
        let athletes: [NewAthlete] = await queryAWSAthletes().filter { $0.user.id == user.id }
        if athletes.count != 1 { print("count not 1"); return nil }
        var athlete = athletes[0]
        
        // TODO: this is not publishing to DataStore due to GraphQL error
        athlete.springboardRating = nil
        athlete.platformRating = nil
        athlete.totalRating = nil
        
        return try await saveToDataStore(object: athlete)
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
                NavigationLink {
                    if let user = newUser {
                        NavigationLink {
                            CommittedCollegeView(selectedCollege: $selectedCollege, newUser: user)
                        } label: {
                            Text("Change Commited College")
                        }
                    }
                } label: {
                    Label("Profile", systemImage: "person")
                }
                
                NavigationLink {
                    VStack {
                        Button {
                            showDeleteAccountAlert = true
                        } label: {
                            Text("Delete Account")
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                        .disabled(isDeletingAccount)
                        
                        if isDeletingAccount {
                            ProgressView()
                        }
                    }
                    .alert("Are you sure you want to permanently delete your account? This action cannot be undone.", 
                           isPresented: $showDeleteAccountAlert) {
                        Button("Cancel", role: .cancel) {
                            print("Cancel delete account")
                            showDeleteAccountAlert = false
                        }
                        Button("Delete", role: .destructive) {
                            Task {
                                print("Initiating account deletion...")
                                isDeletingAccount = true
                                
                                // Deletes all account data and login
                                await deleteAccount(authUserId: authUserId)
                                
                                // Explicitly sign out of state since it is being observed
                                await state.signOut()
                                
                                showDeleteAccountAlert = false
                            }
                        }
                    }
                } label: {
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
                NavigationLink {
                    if let user = newUser {
                        if user.diveMeetsID != nil {
                            Button {
                                Task {
                                    newUser?.diveMeetsID = nil
                                    
                                    // If account is an Athlete, clear its skill ratings
                                    if newUser?.accountType == "Athlete" {
                                        do {
                                            let _ = try await clearSkillRatings()
                                        } catch {
                                            print("\(error)")
                                        }
                                    }
                                
                                    let _ = try await saveToDataStore(object: newUser!)
                                    
                                    updateDataStoreData = true
                                    
                                    // Dismiss profile entirely so it can be redrawn with
                                    // updated data
                                    showAccount = false
                                }
                            } label: {
                                Text("Unlink DiveMeets Account")
                            }
                        } else {
                            NavigationLink(destination: {
                                DiveMeetsLink(newUser: user, showAccount: $showAccount,
                                              updateDataStoreData: $updateDataStoreData)
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .foregroundColor(Custom.darkGray)
                                        .cornerRadius(50)
                                        .shadow(radius: 10)
                                    Text("Link DiveMeets Account")
                                        .foregroundColor(.primary)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .padding()
                                }
                                .frame(width: linkButtonWidth, height: screenHeight * 0.05)
                            })
                        }
                    }
                } label: {
                    Label("DiveMeets", systemImage: "person")
                }
                NavigationLink {} label: {
                    Label("USA Diving", systemImage: "person")
                }
            }
            
            Button {
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
            } label: {
                Text("Sign out")
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Account")
        .onAppear {
            Task {
                print("appeared")
                if let user = newUser, user.accountType != "Spectator" {
                    print("user not nil")
                    let college: College?
                    switch user.accountType {
                        case "Athlete":
                            guard let athlete = try await getUserAthleteByUserId(id: user.id)
                            else { return }
                            print("athlete: \(athlete.id)")
                            guard let athleteCollege = athlete.college else { print("failed"); return }
                            print("athleteCollege: \(athleteCollege.id)")
                            college = try await queryAWSCollegeById(id: athleteCollege.id)
                            print("college: \(college?.id)")
                        case "Coach":
                            // TODO: implement for coaches to associate with a college
                            print("Coaches can't associate with a College yet")
                            college = nil
                        default:
                            return
                    }
                    
                    if let college = college {
                        print("setting college to \(college.name)")
                        selectedCollege = college.name
                    }
                }
            }
        }
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

// Convenience init for updating skill ratings with new NewAthlete object
extension NewAthlete {
    public init(from: NewAthlete, springboard: Double?, platform: Double?, total: Double?) {
        self.init(id: from.id,
                  user: from.user,
                  team: from.team,
                  college: from.college,
                  heightFeet: from.heightFeet,
                  heightInches: from.heightInches,
                  weight: from.weight,
                  weightUnit: from.weightUnit,
                  gender: from.gender,
                  age: from.age,
                  graduationYear: from.graduationYear,
                  highSchool: from.highSchool,
                  hometown: from.hometown,
                  springboardRating: springboard,
                  platformRating: platform,
                  totalRating: total,
                  dives: from.dives ?? [],
                  collegeID: from.collegeID,
                  newteamID: from.newteamID,
                  createdAt: nil,
                  updatedAt: nil)
    }
}
