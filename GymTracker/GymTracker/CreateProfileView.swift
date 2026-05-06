//
//  CreateProfileView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var height = ""
    @State private var weight = ""
    @State private var age = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Параметры".localized()) {
                    HStack {
                        Text("Рост (см)".localized())
                        Spacer()
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Вес (кг)".localized())
                        Spacer()
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Возраст".localized())
                        Spacer()
                        TextField("30", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Создать профиль".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать".localized()) {
                        createProfile()
                        dismiss()
                    }
                    .disabled(height.isEmpty || weight.isEmpty || age.isEmpty)
                }
            }
        }
    }
    
    private func createProfile() {
        guard let heightValue = Double(height),
              let weightValue = Double(weight),
              let ageValue = Int(age) else { return }
        
        let profile = UserProfile(height: heightValue, initialWeight: weightValue, age: ageValue)
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

#Preview {
    CreateProfileView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self], inMemory: true)
}
