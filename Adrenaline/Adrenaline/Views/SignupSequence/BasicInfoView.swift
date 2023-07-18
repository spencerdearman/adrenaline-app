//
//  BasicInfoView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

enum BasicInfoField: Int, Hashable, CaseIterable {
    case first
    case last
    case email
    case phone
}

struct BasicInfoView: View {
    @Environment(\.colorScheme) var currentMode
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @Binding var selectedOption: AccountType?
    @FocusState private var focusedField: BasicInfoField?
    
    private let screenWidth = UIScreen.main.bounds.width
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private var fieldsFilledIn: Bool {
        firstName != "" && lastName != "" && email != ""
    }
    
    private var bgColor: Color {
        currentMode == .light ? .white : .black
    }
    
    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
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
                            .focused($focusedField, equals: .first)
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .focused($focusedField, equals: .last)
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .focused($focusedField, equals: .email)
                        TextField("Phone (optional)", text: $phone)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: textFieldWidth)
                            .focused($focusedField, equals: .phone)
                        
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
                .onTapGesture {
                    focusedField = nil
                }
                
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
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView(selectedOption: .constant(nil))
    }
}
