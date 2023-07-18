//
//  BasicInfoView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

struct BasicInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var email: String = ""
    @State var phone: String = ""
    @Binding var selectedOption: AccountType?
    
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private var fieldsFilledIn: Bool {
        firstName != "" && lastName != "" && email != ""
    }
    
    var body: some View {
        VStack {
            Text("Signup")
                .font(.title)
                .bold()
            
            Spacer()
            
            ZStack {
                Rectangle()
                    .foregroundColor(Custom.grayThinMaterial)
                    .mask(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 6)
                
                VStack(spacing: 5) {
                    Text("Basic Information")
                        .font(.title2)
                        .bold()
                        .padding()
                    Spacer()
                    
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: textFieldWidth)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: textFieldWidth)
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: textFieldWidth)
                    TextField("Phone (optional)", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: textFieldWidth)
                    
                    Spacer()
                    
                    NavigationLink(destination: ProfileView(profileLink: "")) {
                        Text("Next")
                            .bold()
                    }
                    .buttonStyle(.bordered)
                    .cornerRadius(40)
                    .foregroundColor(.primary)
                    .opacity(!fieldsFilledIn ? 0.5 : 1.0)
                    .disabled(!fieldsFilledIn)
                }
                .padding()
            }
            .frame(width: screenWidth * 0.9, height: 300)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    NavigationViewBackButton()
                }
            }
        }
    }
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView(selectedOption: .constant(nil))
    }
}
