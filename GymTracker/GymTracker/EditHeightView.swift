//
//  EditHeightView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct EditHeightView: View {
    @Bindable var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var heightString: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Рост (см)")
                        Spacer()
                        TextField("См", text: $heightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("Используется для расчёта расхода калорий.")
                }
            }
            .navigationTitle("Изменить рост")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveHeight()
                    }
                    .disabled(heightString.isEmpty)
                }
            }
            .onAppear {
                heightString = String(format: "%.0f", userProfile.height)
            }
        }
    }
    
    private func saveHeight() {
        if let newHeight = Double(heightString) {
            userProfile.height = newHeight
            userProfile.updatedAt = Date()
            try? modelContext.save()
            
            // Sync to Firestore
            Task {
                // Get active program if any
                let descriptor = FetchDescriptor<Program>(
                    predicate: #Predicate<Program> { $0.isActive == true }
                )
                let activeProgram = try? modelContext.fetch(descriptor).first
                
                await SyncManager.shared.syncUserProfile(
                    profile: userProfile,
                    activeProgram: activeProgram,
                    context: modelContext
                )
            }
            
            dismiss()
        }
    }
}
