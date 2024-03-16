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
    @State private var profilePicData: Data? = nil
    @State private var profilePicURL: String = ""
    @State private var showAlert: Bool = false
    @State private var isSavingChanges: Bool = false
    @State private var profilePicUploadFailed: Bool = false
    @Binding var updateDataStoreData: Bool
    @FocusState private var focusedField: SignupInfoField?
    
    var newUser: NewUser?
    
    private var athleteAllFieldsFilled: Bool {
        heightFeet != 0 && heightInches != -1 && weight != 0 && gradYear != 0 &&
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
                                     // TODO: save academics field
                                     heightFeet: heightFeet,
                                     heightInches: Int(heightInches),
                                     weight: weight,
                                     weightUnit: weightUnitString,
                                     gender: newAthlete.gender,
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
                saveButtonPressed = true
            } else {
                saveButtonPressed = false
                showAthleteError = true
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
            Spacer()
            if let _ = newUser {
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
                            ProfileImage(profilePicURL: profilePicURL)
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
                        isSavingChanges = true
                        profilePicUploadFailed = false
                        
                        if let data = profilePicData, let id = newUser?.id {
                            try await uploadProfilePictureForReview(data: data, userId: id)
                            try await Task.sleep(seconds: 10)
                            
                            // If identity verification fails, no changes are saved
                            if await hasProfilePictureInReview(userId: id) {
                                profilePicUploadFailed = true
                                isSavingChanges = false
                                return
                            }
                            
                            showAlert = true
                        }
                        
                        await saveNewAthlete()
                        
                        updateDataStoreData = true
                        profilePicUploadFailed = false
                        isSavingChanges = false
                        dismiss()
                    }
                } label: {
                    ColorfulButton(title: "Save")
                }
                .disabled(isSavingChanges)
                
                Text("**Cancel**")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                    .foregroundColor(isSavingChanges ? .secondary.opacity(0.5) : .primary.opacity(0.7))
                    .accentColor(isSavingChanges ? .secondary.opacity(0.5) : .primary.opacity(0.7))
                    .onTapGesture {
                        dismiss()
                    }
                    .disabled(isSavingChanges)
                
                if profilePicUploadFailed {
                    Text("Failed to verify identity. Make sure your face is visible and matches the photo ID you uploaded when you signed up")
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                } else if showAthleteError {
                    Text("Error creating athlete profile, please check information")
                        .foregroundColor(.primary).fontWeight(.semibold)
                } else if isSavingChanges {
                    VStack {
                        Text("Saving changes")
                        ProgressView()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Edit Athlete Profile")
        .alert("It may take up to 60 seconds for your profile picture to update", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
                dismiss()
            }
        }
        .onChange(of: selectedImage) {
            Task {
                guard let selectedImage = selectedImage else { return }
                
                // Load Picker image into Image
                let _ = loadTransferable(from: selectedImage)
                
                // Load Picker image into Data
                if let data = try? await selectedImage.loadTransferable(type: Data.self) {
                    profilePicData = data
                }
            }
        }
        .onAppear {
            Task {
                profilePic = nil
                isSavingChanges = false
                profilePicUploadFailed = false
                
                if let user = newUser {
                    athlete = try await user.athlete
                    
                    if await hasProfilePicture(userId: user.id) {
                        profilePicURL = getProfilePictureURL(userId: user.id)
                        print(profilePicURL)
                    }
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
