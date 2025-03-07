//
//  CollegeView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 2/10/24.
//

import SwiftUI

struct CollegeView: View {
    let college: College
    @State private var coach: CoachUser? = nil
    @State private var coachUser: NewUser? = nil
    @State private var athletes: [NewUser: NewAthlete] = [:]
    
    private let screenWidth = UIScreen.main.bounds.width
    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        VStack {
            VStack {
                Image(getCollegeImageFilename(name: college.name))
                    .resizable()
                    .clipShape(Circle())
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: screenWidth * 0.4,
                           height: screenWidth * 0.4)
                    .shadow(radius: 15)
                
                Text(college.name)
                    .font(.largeTitle)
                    .bold()
                    .padding([.horizontal, .bottom])
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Coach")
                        .font(.title)
                        .bold()
                        .padding(.top)
                    
                    if let coachUser = coachUser {
                        NavigationLink {
                            AdrenalineProfileView(newUser: coachUser)
                        } label: {
                            CollegeBubbleView(user: coachUser)
                                .padding(.bottom)
                        }
                    } else {
                        VStack {
                            Text("There is no coach associated with this college")
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical)
                    }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Athletes")
                        .font(.title)
                        .bold()
                    
                    if athletes.count > 0 {
                        ForEach(athletes.sorted(by: {
                            $0.key.firstName + " " + $0.key.lastName < $1.key.firstName + " " + $1.key.lastName
                        }), id: \.key) { user, athlete in
                            NavigationLink {
                                AdrenalineProfileView(newUser: user)
                            } label: {
                                CollegeBubbleView(user: user)
                            }
                        }
                    } else {
                        VStack {
                            Text("There are no athletes associated with this college")
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom)
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                let coach = try await college.coach
                if let coach = coach {
                    self.coach = coach
                    coachUser = try await coach.user
                }
                
                try await college.athletes?.fetch()
                guard let athletes = college.athletes?.elements else { return }
                for athlete in athletes {
                    let user = try await athlete.user
                    self.athletes[user] = athlete
                }
            }
        }
    }
}

struct CollegeBubbleView: View {
    let user: NewUser
    
    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Custom.specialGray)
                .shadow(radius: 5)
            HStack(alignment: .center) {
                ProfileImage(profilePicURL: getProfilePictureURL(userId: user.id, 
                                                                 firstName: user.firstName,
                                                                 lastName: user.lastName,
                                                                 dateOfBirth: user.dateOfBirth))
                .frame(width: 100, height: 100)
                .scaleEffect(0.3)
                HStack(alignment: .firstTextBaseline) {
                    Text((user.firstName) + " " + (user.lastName))
                        .foregroundColor(.primary)
                        .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(height: 100)
        .padding([.leading, .trailing])
    }
}
