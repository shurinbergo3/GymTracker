//
//  AddWeightView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let userProfile: UserProfile
    
    @State private var weight = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Новый вес") {
                    HStack {
                        Text("Вес (кг)")
                        Spacer()
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(DesignSystem.Typography.body())
                    }
                    
                    HStack {
                        Text("Дата")
                        Spacer()
                        Text(Date().formatted(date: .long, time: .omitted))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(DesignSystem.Typography.body())
                    }
                }
            }
            .navigationTitle("Добавить вес")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        addWeight()
                        dismiss()
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
    
    private func addWeight() {
        guard let weightValue = Double(weight) else { return }
        
        let weightRecord = WeightRecord(weight: weightValue, date: Date())
        weightRecord.userProfile = userProfile
        userProfile.weightHistory.append(weightRecord)
        userProfile.updatedAt = Date()
        
        try? modelContext.save()
    }
}

struct AddWeightView_PreviewWrapper: View {
    let container: ModelContainer
    let profile: UserProfile
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: UserProfile.self, WeightRecord.self, configurations: config)
        } catch {
            fatalError("Failed to create preview container")
        }
        profile = UserProfile(height: 180, initialWeight: 70)
        container.mainContext.insert(profile)
    }
    
    var body: some View {
        AddWeightView(userProfile: profile)
            .modelContainer(container)
    }
}

#Preview {
    AddWeightView_PreviewWrapper()
}
