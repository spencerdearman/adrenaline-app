//
//  AdrenalineProfileView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 7/18/23.
//

import SwiftUI

struct AdrenalineProfileView: View {
    @Binding var signupData: SignupData
    @Binding var selectedOption: AccountType?
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                BackgroundSpheres()
                    .frame(height: geometry.size.height * 0.7)
                BackgroundBubble(content: Text("Welcome " + (signupData.firstName ?? ""))
                    .font(.title2).fontWeight(.semibold)
                    .foregroundColor(.primary))
            }
        }
    }
}

//struct RecruitingData: Hashable {
//    var height: Height?
//    var weight: Int?
//    var gender: String?
//    var age: Int?
//    var gradYear: Int?
//    var highSchool: String?
//    var hometown: String?
//}
//
//struct Height: Hashable {
//    var feet: Int
//    var inches: Int
//}
//

struct AdrenalineProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let s  = SignupData(accountType: AccountType(rawValue: "athlete"), firstName: "Spencer", lastName: "Dearman", email: "dearmanspencer@gmail.com", phone: "571-758-8292", recruiting: RecruitingData(height: Height(feet: 6, inches: 0), weight: 168, gender: "Male", age: 19, gradYear: 2022, highSchool: "Oakton High School", hometown: "Oakton"))
        AdrenalineProfileView(signupData: .constant(s), selectedOption: .constant(nil))
    }
}
