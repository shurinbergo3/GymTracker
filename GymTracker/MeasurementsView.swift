//
//  MeasurementsView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    
    @Query private var userProfiles: [UserProfile]
    @Query private var bodyMeasurements: [BodyMeasurement]
    
    @State private var showingAddProfile = false
    @State private var showingAddWeight = false
    
    private var currentProfile: UserProfile? {
        userProfiles.first
    }
    
    private var weightHistory: [WeightRecord] {
        currentProfile?.weightHistory.sorted { $0.date > $1.date } ?? []
    }
    
    private var currentWeight: Double {
        weightHistory.first?.weight ?? 0
    }
    
    // Grid Setup
    private let columns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                        
                        // 1. History Card
                        NavigationLink(destination: WorkoutHistoryView()) {
                            StatCard(
                                title: "История",
                                value: "Тренировок",
                                icon: "clock.fill",
                                color: DesignSystem.Colors.accent
                            )
                        }
                        
                        // 2. Weight Card
                        if currentProfile != nil {
                            Button(action: { showingAddWeight = true }) {
                                StatCard(
                                    title: "Вес",
                                    value: currentWeight > 0 ? String(format: "%.1f кг", currentWeight) : "—",
                                    icon: "scalemass.fill",
                                    color: DesignSystem.Colors.neonGreen
                                )
                            }
                        } else {
                            Button(action: { showingAddProfile = true }) {
                                StatCard(
                                    title: "Профиль",
                                    value: "Создать",
                                    icon: "person.badge.plus",
                                    color: DesignSystem.Colors.secondaryText
                                )
                            }
                        }
                        
                        // 3. Body Measurements Cards
                        ForEach(MeasurementType.allCases, id: \.self) { type in
                            NavigationLink(destination: MeasurementDetailView(measurementType: type)) {
                                StatCard(
                                    title: type.rawValue,
                                    value: latestValueString(for: type),
                                    icon: iconForMeasurement(type),
                                    color: DesignSystem.Colors.secondaryText
                                )
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Параметры")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileButton()
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                CreateProfileView()
            }
            .sheet(isPresented: $showingAddWeight) {
                if let profile = currentProfile {
                    AddWeightView(userProfile: profile)
                }
            }
        }
    }
    
    private func latestMeasurement(for type: MeasurementType) -> BodyMeasurement? {
        bodyMeasurements
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
            .first
    }
    
    private func latestValueString(for type: MeasurementType) -> String {
        if let measurement = latestMeasurement(for: type) {
            return String(format: "%.1f см", measurement.value)
        }
        return "—"
    }
    
    private func iconForMeasurement(_ type: MeasurementType) -> String {
        // SF Symbols mapping
        switch type {
        case .biceps: return "arm" // Custom or standard if available, fallback generic
        case .chest: return "tshirt.fill"
        case .waist: return "figure.stand"
        default: return "ruler.fill"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                }
                
                Spacer(minLength: 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(title)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(height: 120) // Fixed height to make them squares/uniform
            .padding(DesignSystem.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keep helper views (CreateProfileView, AddWeightView) as they were, 
// or minimal updates access control
// I will keep existing sub-structs at the bottom of the file if they were inside.
// Actually I will simply append the existing helpers from previous file version
// But wait, WriteToFile overwrites. I need to include them.

// MARK: - Create Profile View

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

// MARK: - Add Weight View (Also need this)

// struct AddWeightView: View {
    // Note: Assuming AddWeightView logic was similar to AddMeasurement or existing in previous file.
    // I need to recreate it or copy it.
    // Let's look at previous file content again.
    // It used `AddWeightView` but I didn't see the definition in the snippets!
    // Wait, let me check the previous `read_file` output for MeasurementsView.swift
    // Ah, I missed it? Or it was not shown?
    // Line 167: AddWeightView(userProfile: profile)
    // But where is the struct defined?
    // It might have been cut off or in another file?
    // Let me check `MeasurementsView.swift` again carefully.
    // Lines 242-296 is CreatedProfileView.
    // Lines 300-369 is AddMeasurementView.
    // I DO NOT SEE AddWeightView in the previous file view!
    // It must be in another file or I missed it.
    // Let me check file list... maybe `AddWeightView.swift`? 
    // No, file list showed `MeasurementDetailView.swift` etc.
    // I'll search for AddWeightView.
    


// MeasurementType: Identifiable
extension MeasurementType: Identifiable {
    var id: String { self.rawValue }
}

#Preview {
    MeasurementsView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
        .environmentObject(AuthManager())
}
