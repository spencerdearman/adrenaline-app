//
//  AccountTypeSelectView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 7/18/23.
//

import SwiftUI

enum AccountType: String, CaseIterable {
    case athlete = "Athlete"
    case coach = "Coach"
    case spectator = "Spectator"
}

struct AccountTypeSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @State var selectedOption: AccountType? = nil
    
    private let athleteDesc: String = "You are looking to follow the results of your sport and get noticed by college coaches"
    private let coachDesc: String = "You are looking to follow the results of your sport and seek out athletes to bring to your program"
    private let spectatorDesc: String = "You are looking to follow the results of a sport without any interest in recruiting"
    
    var body: some View {
        VStack {
            Text("Signup")
                .font(.title)
                .bold()
            
            Spacer()
            
            VStack(spacing: 20) {
                Text("Which type of account would you like to create?")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                OptionView(selectedOption: $selectedOption, optionType: .athlete, optionDescription: athleteDesc)
                OptionView(selectedOption: $selectedOption, optionType: .coach, optionDescription: coachDesc)
                OptionView(selectedOption: $selectedOption, optionType: .spectator, optionDescription: spectatorDesc)
                
                NavigationLink(destination: BasicInfoView(selectedOption: $selectedOption)) {
                    Text("Next")
                        .bold()
                }
                .buttonStyle(.bordered)
                .cornerRadius(40)
                .foregroundColor(.primary)
                .opacity(selectedOption == nil ? 0.5 : 1.0)
                .disabled(selectedOption == nil)
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

struct OptionView: View {
    @Binding var selectedOption: AccountType?
    var optionType: AccountType
    var optionDescription: String
    var selectedColor: Color = .gray
    
    private let screenWidth = UIScreen.main.bounds.width
    private var showBorder: Bool {
        selectedOption == optionType
    }
    
    var body: some View {
        ZStack {
            Rectangle()
            .foregroundColor(Custom.grayThinMaterial)
            .mask(RoundedRectangle(cornerRadius: 40))
            .shadow(radius: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(selectedColor, lineWidth: showBorder ? 2 : 0)
            )
            
            VStack(spacing: 10) {
                Text(optionType.rawValue)
                    .font(.title3)
                    .bold()
                Text(optionDescription)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .frame(width: screenWidth * 0.95, height: 125)
        .onTapGesture {
            selectedOption = optionType
        }
    }
}

//struct CoachOptionView: View {
//    @Binding var selectedOption: AccountType?
//
//    private let screenWidth = UIScreen.main.bounds.width
//    private var showBorder: Bool {
//        selectedOption == .coach
//    }
//
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .foregroundColor(Custom.grayThinMaterial)
//                .mask(RoundedRectangle(cornerRadius: 40))
//                .shadow(radius: 6)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 40)
//                        .stroke(lineWidth: showBorder ? 1 : 0)
//                )
//
//            VStack(spacing: 10) {
//                Text("Coach")
//                    .font(.title3)
//                    .bold()
//                Text()
//                    .font(.subheadline)
//                    .multilineTextAlignment(.center)
//            }
//            .padding()
//        }
//        .frame(width: screenWidth * 0.95, height: 125)
//        .onTapGesture {
//            selectedOption = .coach
//        }
//    }
//}

struct AccountTypeSelectView_Previews: PreviewProvider {
    static var previews: some View {
        AccountTypeSelectView()
    }
}
