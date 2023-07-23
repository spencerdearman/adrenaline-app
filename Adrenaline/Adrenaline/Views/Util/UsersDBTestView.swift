//
//  UsersDBTestView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/21/23.
//

import SwiftUI

struct UsersDBTestView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.modelDB) var db
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "email", ascending: true)]
    ) var users: FetchedResults<User>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "email", ascending: true)]
    ) var athletes: FetchedResults<Athlete>
    
    var body: some View {
        VStack {
            HStack {
                Button("Add User") {
                    db.addUser(firstName: "Beck", lastName: "Benson",
                               email: "rlbenson@uchicago.edu", phone: nil, password: "12345")
                }
                Spacer()
                Button("Add Athlete") {
                    db.addAthlete(firstName: "Logan", lastName: "Sherwin",
                                  email: "lsherwin@uchicago.edu", phone: "7247713142",
                                  password: "password", heightFeet: 5, heightInches: 8, weight: 175,
                                  weightUnit: "lb", gender: "Male", age: 22, gradYear: 2023,
                                  highSchool: "Penn-Trafford", hometown: "Pittsburgh, PA")
                }
                Spacer()
                Group {
                    Button("Update Skill Rating") {
                        db.updateAthleteSkillRating(email: "lsherwin@uchicago.edu",
                                                    springboardRating: 100.0, platformRating: 50.0)
                    }
                    Spacer()
                    Button("Set Springboard") {
                        db.updateAthleteSkillRating(email: "lsherwin@uchicago.edu",
                                                    springboardRating: 100.0)
                    }
                    Spacer()
                    Button("Set Platform") {
                        db.updateAthleteSkillRating(email: "lsherwin@uchicago.edu",
                                                    platformRating: 50.0)
                    }
                }
                Spacer()
                Button("Drop All") {
                    db.dropAllUsers()
                }
            }
            .padding()
            
            List(users) { user in
                HStack {
                    if let email = user.email {
                        Text(email)
                    }
                    if let diveMeetsID = user.diveMeetsID {
                        Text(diveMeetsID)
                    }
                }
            }
            List(athletes) { user in
                HStack {
                    if let email = user.email {
                        Text(email)
                    }
                    if let diveMeetsID = user.diveMeetsID {
                        Text(diveMeetsID)
                    }
                    VStack {
                        Text(String(user.springboardRating))
                        Text(String(user.platformRating))
                        Text(String(user.totalRating))
                    }
                }
            }
        }
    }
}
