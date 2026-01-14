
import SwiftUI
import SwiftData

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
                        Text(measurementType.rawValue)
                        Spacer()
                        TextField("0.0", text: $value)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("см")
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker("Дата", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Добавить замер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
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
    }
}
