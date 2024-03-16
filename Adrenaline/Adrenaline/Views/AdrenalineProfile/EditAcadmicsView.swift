//
//  EditAcadmicsView.swift
//  Adrenaline
//
//  Created by Spencer Dearman on 3/15/24.
//

import SwiftUI
import Amplify
import PhotosUI

struct EditAcademicsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var academics: AcademicRecord? = nil
    @State private var savedAthlete: NewAthlete? = nil
    @State var satScore: Int? = nil
    @State var actScore: Int? = nil
    @State var weightedGPA: Double? = nil
    @State var gpaScale: Double? = nil
    @State var coursework: String = ""
    @State var academicCreationSuccessful: Bool = false
    @State private var saveButtonPressed: Bool = false
    @State private var showAthleteError: Bool = false
    @State private var showSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var isSavingChanges: Bool = false
    @Binding var updateDataStoreData: Bool
    @FocusState private var focusedField: SignupInfoField?
    
    var newUser: NewUser?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height
    private var textFieldWidth: CGFloat {
        screenWidth * 0.5
    }
    
    private func minMax <T: Numeric> (value: T, lowerBound: T, upperBound: T) -> T where T: Comparable {
        return min(max(value, lowerBound), upperBound)
    }
    
    func saveAcademics() async {
        do {
            guard var athlete = savedAthlete else { return }
            guard var user =  newUser else { return }
            
            let record = AcademicRecord(
                athlete: athlete,
                satScore: satScore,
                actScore: actScore,
                weightedGPA: weightedGPA,
                gpaScale: gpaScale,
                coursework: coursework)
            
            // Save the record item
            let savedItem = try await Amplify.DataStore.save(record)
            
            // Updating athlete item
            athlete.setAcademics(savedItem)
            athlete.newAthleteAcademicsId = savedItem.id
            savedAthlete = try await saveToDataStore(object: athlete)
            
            //
            user.setAthlete(athlete)
            user.newUserAthleteId = athlete.id
            let _ = try await saveToDataStore(object: user)
            
            withAnimation(.openCard) {
                academicCreationSuccessful = true
            }
            print("Saved item: \(savedItem)")
        } catch let error as DataStoreError {
            withAnimation(.closeCard) {
                academicCreationSuccessful = false
            }
            print("Error creating item: \(error)")
        } catch {
            withAnimation(.closeCard) {
                academicCreationSuccessful = false
            }
            print("Unexpected error: \(error)")
        }
    }
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    TextField("SAT Score", value: $satScore, format: .year())
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                    iconColor: nil))
                        .focused($focusedField, equals: .sat)
                        .onChange(of: satScore) {
                            guard let sat = satScore else { return }
                            satScore = minMax(value: sat, lowerBound: 0, upperBound: 1600)
                        }
                    
                    TextField("ACT Score", value: $actScore, format: .number)
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                    iconColor: nil))
                        .focused($focusedField, equals: .act)
                        .onChange(of: actScore) {
                            guard let act = actScore else { return }
                            actScore = minMax(value: act, lowerBound: 0, upperBound: 36)
                        }
                }
                
                TextField("Weighted GPA", value: $weightedGPA, format: .number)
                    .keyboardType(.decimalPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: nil))
                    .focused($focusedField, equals: .gpa)
                    .onChange(of: weightedGPA) {
                        guard let gpa = weightedGPA else { return }
                        weightedGPA = minMax(value: gpa, lowerBound: 0.0, upperBound: 6.0)
                    }
                
                TextField("GPA Scale", value: $gpaScale, format: .number)
                    .keyboardType(.decimalPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: nil))
                    .focused($focusedField, equals: .gpaScale)
                    .onChange(of: gpaScale) {
                        guard let scale = gpaScale else { return }
                        gpaScale = minMax(value: scale, lowerBound: 0.0, upperBound: 6.0)
                    }
                
                TextField("Coursework", text: $coursework, axis: .vertical)
                    .disableAutocorrection(true)
                    .lineLimit(4)
                    .modifier(TextFieldModifier(icon: "hexagon.fill",
                                                iconColor: nil))
                    .focused($focusedField, equals: .hometown)
                    .onChange(of: coursework) {
                        coursework = coursework
                    }
                
                Divider()
                
                Button {
                    Task {
                        isSavingChanges = true
                        await saveAcademics()
                        updateDataStoreData = true
                        isSavingChanges = false
                        print("UPDATED")
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
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Edit Profile")
        .alert("It may take up to 60 seconds for your profile picture to update", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
                dismiss()
            }
        }
        .onAppear {
            Task {
                isSavingChanges = false
                
                if let user = newUser {
                    savedAthlete = try await user.athlete
                    if let athlete = savedAthlete {
                        academics = try await athlete.academics
                    }
                }
                
                if let academics = academics {
                    satScore = academics.satScore
                    actScore = academics.actScore
                    weightedGPA = academics.weightedGPA
                    gpaScale = academics.gpaScale
                    coursework = academics.coursework ?? ""
                }
            }
        }
    }
}
