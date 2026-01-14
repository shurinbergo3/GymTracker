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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Параметры") {
                    HStack {
                        Text("Рост (см)")
                        Spacer()
                        TextField("170", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Вес (кг)")
                        Spacer()
                        TextField("70", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Создать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        createProfile()
                        dismiss()
                    }
                    .disabled(height.isEmpty || weight.isEmpty)
                }
            }
        }
    }
    
    private func createProfile() {
        guard let heightValue = Double(height),
              let weightValue = Double(weight) else { return }
        
        let profile = UserProfile(height: heightValue, initialWeight: weightValue)
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

#Preview {
    CreateProfileView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self], inMemory: true)
}
