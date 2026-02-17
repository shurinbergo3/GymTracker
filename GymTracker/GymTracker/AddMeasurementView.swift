
import SwiftUI
import SwiftData
import FirebaseAuth

struct AddMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let measurementType: MeasurementType
    
    @State private var value = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Новый замер") {
                    HStack {
                        Text(measurementType.localizedName)
                        Spacer()
                        TextField("0.0", text: $value)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("см".localized())
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Дата", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Добавить замер".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить".localized()) {
                        saveMeasurement()
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
    
    private func saveMeasurement() {
        guard let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let measurement = BodyMeasurement(
            date: date,
            type: measurementType,
            value: doubleValue
        )
        modelContext.insert(measurement)
        try? modelContext.save()
        
        // Sync to Firestore
        Task {
            // Get user profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            guard let profile = try? modelContext.fetch(profileDescriptor).first else { return }
            
            // Get active program if any
            let programDescriptor = FetchDescriptor<Program>(
                predicate: #Predicate<Program> { $0.isActive == true }
            )
            let activeProgram = try? modelContext.fetch(programDescriptor).first
            
            await SyncManager.shared.syncUserProfile(
                profile: profile,
                activeProgram: activeProgram,
                context: modelContext
            )
        }
    }
}
