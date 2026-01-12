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
    @Query private var userProfiles: [UserProfile]
    @Query private var bodyMeasurements: [BodyMeasurement]
    
    @State private var showingAddProfile = false
    
    private var currentProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Кнопка истории тренировок
                        WorkoutHistoryButtonLarge()
                        
                        // Секция основных параметров
                        BasicParametersSection(profile: currentProfile)
                        
                        // Кнопка быстрого доступа к замерам
                        BodyMeasurementsButtonSection()
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Параметры")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if currentProfile == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddProfile = true }) {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                CreateProfileView()
            }
        }
    }
}

// MARK: - Basic Parameters Section

struct BasicParametersSection: View {
    let profile: UserProfile?
    @State private var showingAddWeight = false
    
    // Получаем историю веса, отсортированную по дате (новые сверху)
    private var weightHistory: [WeightRecord] {
        profile?.weightHistory.sorted { $0.date > $1.date } ?? []
    }
    
    private var currentWeight: WeightRecord? {
        weightHistory.first
    }
    
    private var olderWeights: [WeightRecord] {
        Array(weightHistory.dropFirst().prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Основное")
                .font(DesignSystem.Typography.title2())
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if let profile = profile {
                CardView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Рост - Увеличенные цифры
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("РОСТ")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.2)
                                
                                Text("\(String(format: "%.0f", profile.height)) см")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                        
                        // Вес с графиком
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("ВЕС")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .tracking(1.2)
                                    
                                    // Текущий вес
                                    if let current = currentWeight {
                                        Text("\(String(format: "%.1f", current.weight)) кг")
                                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                    } else {
                                        Text("—")
                                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { showingAddWeight = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                }
                            }
                            
                            // Weight Chart
                            WeightChartView(weightHistory: weightHistory)
                            
                            // Previous weights (compact list)
                            if !olderWeights.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(olderWeights.enumerated()), id: \.element.date) { index, record in
                                        Text(String(format: "%.1f кг", record.weight))
                                            .font(DesignSystem.Typography.caption())
                                            .strikethrough()
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                            .opacity(1.0 - (Double(index + 1) * 0.25))
                                    }
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.xl)
                }
            } else {
                CardView {
                    Text("Добавьте свой профиль, чтобы отслеживать параметры")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(DesignSystem.Spacing.xl)
                }
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            if let profile = profile {
                AddWeightView(userProfile: profile)
            }
        }
    }
}

// MARK: - Body Measurements Section

struct BodyMeasurementsSection: View {
    let measurements: [BodyMeasurement]
    
    private func latestMeasurement(for type: MeasurementType) -> BodyMeasurement? {
        measurements
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
            .first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Замеры тела")
                .font(DesignSystem.Typography.title2())
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.md) {
                ForEach(MeasurementType.allCases, id: \.self) { type in
                    NavigationLink(destination: MeasurementDetailView(measurementType: type)) {
                        MeasurementCard(
                            type: type,
                            latestValue: latestMeasurement(for: type)?.value
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Measurement Card

struct MeasurementCard: View {
    let type: MeasurementType
    let latestValue: Double?
    
    var body: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.md) {
                Text(type.rawValue)
                    .font(DesignSystem.Typography.callout())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.0)
                
                if let value = latestValue {
                    Text("\(String(format: "%.1f", value)) см")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                } else {
                    Text("—")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

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

// MARK: - Add Measurement View

struct AddMeasurementView: View {
    let measurementType: MeasurementType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var measurements: [BodyMeasurement]
    
    @State private var value = ""
    
    private var history: [BodyMeasurement] {
        measurements
            .filter { $0.type == measurementType }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Новое значение") {
                    HStack {
                        Text("Значение (см)")
                        Spacer()
                        TextField("0", text: $value)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if !history.isEmpty {
                    Section("История") {
                        ForEach(history, id: \.self) { measurement in
                            HStack {
                                Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(DesignSystem.Typography.callout())
                                
                                Spacer()
                                
                                Text(String(format: "%.1f см", measurement.value))
                                    .font(DesignSystem.Typography.callout())
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle(measurementType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        addMeasurement()
                        dismiss()
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
    
    private func addMeasurement() {
        guard let measurementValue = Double(value) else { return }
        
        let measurement = BodyMeasurement(type: measurementType, value: measurementValue)
        modelContext.insert(measurement)
        try? modelContext.save()
    }
}


// MARK: - Body Measurements Button Section

struct BodyMeasurementsButtonSection: View {
    @State private var showingBodyMeasurementEditor = false
    
    var body: some View {
        Button(action: { showingBodyMeasurementEditor = true }) {
            CardView {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Замеры тела")
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Отслеживайте изменения")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingBodyMeasurementEditor) {
            BodyMeasurementEditorView()
        }
    }
}

// MARK: - Workout History Button Section

struct WorkoutHistoryButton: View {
    @State private var showingHistory = false
    
    var body: some View {
        NavigationLink(destination: WorkoutHistoryView()) {
            CardView {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("История тренировок")
                            .font(DesignSystem.Typography.title3())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Просмотр прошлых тренировок")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Для sheet presentation
extension MeasurementType: Identifiable {
    var id: String { self.rawValue }
}


#Preview {
    MeasurementsView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
}
