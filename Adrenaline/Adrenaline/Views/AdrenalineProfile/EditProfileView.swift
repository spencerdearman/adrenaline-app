//
//  EditProfileView.swift
//  Adrenaline
//
//  Created by Logan Sherwin on 1/27/24.
//

import SwiftUI
import Amplify
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var athlete: NewAthlete? = nil
    @State var heightFeet: Int = 0
    @State var heightInches: Double = -.infinity
    @State var weight: Int = 0
    @State var weightUnit: WeightUnit = .lb
    @State var weightUnitString: String = ""
    @State var gradYear: Int = 0
    @State var highSchool: String = ""
    @State var hometown: String = ""
    @State private var saveButtonPressed: Bool = false
    @State private var showAthleteError: Bool = false
    @State private var showSheet: Bool = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var profilePic: Image? = nil
    @Binding var updateDataStoreData: Bool
    @FocusState private var focusedField: SignupInfoField?
    
    var newUser: NewUser?
    
    private var athleteAllFieldsFilled: Bool {
        heightFeet != 0 && heightInches != -1 && weight != 0 && athlete?.age != 0 && gradYear != 0 &&
        !highSchool.isEmpty && !hometown.isEmpty
    }
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    func saveNewAthlete() async {
        do {
            guard var user = newUser else { return }
            guard let newAthlete = athlete else { return }
            print("Printing the saved User: \(user)")
            
            // Create the athlete item using the saved user, team, and college
            let athlete = NewAthlete(id: newAthlete.id,
                                     user: user,
                                     heightFeet: heightFeet,
                                     heightInches: Int(heightInches),
                                     weight: weight,
                                     weightUnit: weightUnitString,
                                     gender: newAthlete.gender,
                                     age: newAthlete.age,
                                     graduationYear: gradYear,
                                     highSchool: highSchool,
                                     hometown: hometown,
                                     springboardRating: newAthlete.springboardRating,
                                     platformRating: newAthlete.platformRating,
                                     totalRating: newAthlete.totalRating)
            
            // Save the athlete item
            let savedItem = try await Amplify.DataStore.save(athlete)
            
            user.setAthlete(savedItem)
            user.newUserAthleteId = savedItem.id
            let _ = try await saveToDataStore(object: user)
            
            print("Saved item: \(savedItem)")
        } catch let error as DataStoreError {
            print("Error creating item: \(error)")
        } catch {
            print("Unexpected error: \(error)")
        }
        withAnimation(.openCard) {
            if athleteAllFieldsFilled {
                saveButtonPressed = false
                showAthleteError = true
            } else {
                saveButtonPressed = true
            }
        }
    }
    
    func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard selectedImage == self.selectedImage else { return }
                switch result {
                    case .success(let image?):
                        // Handle the success case with the image.
                        profilePic = image
                    case .success(nil):
                        // Handle the success case with an empty value.
                        profilePic = nil
                    case .failure(let error):
                        // Handle the failure case with the provided error.
                        print("Failed to get image from picker: \(error)")
                        profilePic = nil
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            if let user = newUser {
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        if let profilePic = profilePic {
                            profilePic
                                .resizable()
                                .scaledToFit()
                                .frame(width:170, height:300)
                                .clipShape(Circle())
                                .overlay {
                                    Circle().stroke(.ultraThinMaterial, lineWidth: 15)
                                }
                                .shadow(radius: 7)
                                .frame(width: 200, height: 130)
                                .scaleEffect(0.9)
                        } else {
                            ProfileImage(diverID: (user.diveMeetsID ?? ""))
                                .frame(width: 200, height: 130)
                                .scaleEffect(0.9)
                        }
                        
                        Image(systemName: "plus")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .background(.gray)
                            .clipShape(Circle())
                            .offset(x: -25, y: 15)
                    }
                    .padding(.bottom, 30)
                }
            }
            
            Group {
                HStack {
                    TextField("Height (ft)", value: $heightFeet, formatter: .heightFtFormatter)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                    iconColor: saveButtonPressed && heightFeet == 0
                                                    ? Custom.error
                                                    : nil))
                        .focused($focusedField, equals: .heightFeet)
                        .onChange(of: heightFeet) {
                            heightFeet = heightFeet
                        }
                    
                    TextField("Height (in)", value: $heightInches, formatter: .heightInFormatter)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                    iconColor: saveButtonPressed && heightInches == 0
                                                    ? Custom.error
                                                    : nil))
                        .focused($focusedField, equals: .heightInches)
                        .onChange(of: heightInches) {
                            heightInches = heightInches
                        }
                }
                
                HStack {
                    TextField("Weight", value: $weight, formatter: .weightFormatter)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                    iconColor: saveButtonPressed && weight == 0
                                                    ? Custom.error
                                                    : nil))
                        .focused($focusedField, equals: .weight)
                    
                    BubbleSelectView(selection: $weightUnit)
                        .frame(width: textFieldWidth / 2, height: screenHeight * 0.02)
                        .scaleEffect(1.08)
                        .onChange(of: weightUnit) {
                            weightUnitString = weightUnit.rawValue
                        }
                }
                
                TextField("Graduation Year", value: $gradYear, formatter: .yearFormatter)
                    .keyboardType(.numberPad)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: saveButtonPressed && gradYear == 0
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .gradYear)
                    .onChange(of: gradYear) {
                        gradYear = gradYear
                    }
                
                TextField("High School", text: $highSchool)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: saveButtonPressed && highSchool.isEmpty
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .highSchool)
                    .onChange(of: highSchool) {
                        highSchool = highSchool
                    }
                
                TextField("Hometown", text: $hometown)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: saveButtonPressed && hometown.isEmpty
                                                ? Custom.error
                                                : nil))
                    .focused($focusedField, equals: .hometown)
                    .onChange(of: hometown) {
                        hometown = hometown
                    }
                
                Divider()
                
                
                Button {
                    withAnimation(.closeCard) {
                        showAthleteError = false
                    }
                    Task {
                        await saveNewAthlete()
                        updateDataStoreData = true
                        dismiss()
                    }
                } label: {
                    ColorfulButton(title: "Save")
                }
                
                if showAthleteError {
                    Text("Error creating athlete profile, please check information")
                        .foregroundColor(.primary).fontWeight(.semibold)
                }
                
                Text("**Cancel**")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary.opacity(0.7))
                    .accentColor(.primary.opacity(0.7))
                    .onTapGesture {
                        dismiss()
                    }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Edit Profile")
        .onChange(of: selectedImage) {
            guard let selectedImage = selectedImage else { return }
            let _ = loadTransferable(from: selectedImage)
        }
        .onAppear {
            Task {
                if let user = newUser {
                    athlete = try await user.athlete
                }
                
                if let athlete = athlete {
                    hometown = athlete.hometown
                    highSchool = athlete.highSchool
                    heightFeet = athlete.heightFeet
                    heightInches = Double(athlete.heightInches)
                    weight = athlete.weight
                    weightUnit = WeightUnit(rawValue: athlete.weightUnit) ?? .lb
                    weightUnitString = weightUnit.rawValue
                    gradYear = athlete.graduationYear
                }
            }
        }
    }
}
