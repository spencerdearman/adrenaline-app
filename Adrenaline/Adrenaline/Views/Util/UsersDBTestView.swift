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
                    db.addUser(firstName: "Beck", lastName: "Benson", email: "rlbenson@uchicago.edu",
                               phone: nil, password: "12345")
                }
                Button("Add Athlete") {
                    db.addAthlete(firstName: "Logan", lastName: "Sherwin", email: "lsherwin@uchicago.edu",
                               phone: "7247713142", password: "password", heightFeet: 5, heightInches: 8,
                               weight: 175, weightUnit: "lb", gender: "Male", age: 22, gradYear: 2023,
                    highSchool: "Penn-Trafford", hometown: "Pittsburgh, PA")
                }
                Button("Drop All") {
                    db.dropAllUsers()
                }
            }
            List(users) { user in
                HStack {
                    if let first = user.firstName, let last = user.lastName {
                        Text(first + " " + last)
                    }
                    if let email = user.email {
                        Text(email)
                    }
                    if let phone = user.phone {
                        Text(phone)
                    }
                    if let password = user.password {
                        Text(password)
                    }
                }
            }
            List(athletes) { user in
                HStack {
                    if let first = user.firstName, let last = user.lastName {
                        Text(first + " " + last)
                    }
                    if let email = user.email {
                        Text(email)
                    }
                    if let phone = user.phone {
                        Text(phone)
                    }
                    if let password = user.password {
                        Text(password)
                    }
                    Text(String(user.heightFeet) + "-" + String(user.heightInches))
                }
            }
        }
    }
}

struct UsersDBTestView_Previews: PreviewProvider {
    static var previews: some View {
        UsersDBTestView()
    }
}
