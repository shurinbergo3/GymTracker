//
//  BodyMeasurementEditorView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct BodyMeasurementEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeasurements: [BodyMeasurement]
    
    // История для каждого типа замера
    private func measurements(for type: MeasurementType) -> [BodyMeasurement] {
        allMeasurements
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
    }
    
    private func latest(for type: MeasurementType) -> BodyMeasurement? {
        measurements(for: type).first
    }
    
    private func olderMeasurements(for type: MeasurementType) -> [BodyMeasurement] {
        Array(measurements(for: type).dropFirst().prefix(3))
    }
    
    // Разделение на заполненные и пустые
    private var filledTypes: [MeasurementType] {
        MeasurementType.allCases.filter { latest(for: $0) != nil }
    }
    
    private var emptyTypes: [MeasurementType] {
        MeasurementType.allCases.filter { latest(for: $0) == nil }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Заполненные замеры
                        if !filledTypes.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("ВАШИ ЗАМЕРЫ")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.2)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                                ForEach(filledTypes, id: \.self) { type in
                                    MeasurementEditCard(
                                        type: type,
                                        latest: latest(for: type),
                                        older: olderMeasurements(for: type)
                                    )
                                }
                            }
                        }
                        
                        // Пустые замеры
                        if !emptyTypes.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("ДОБАВИТЬ ЗАМЕР")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.2)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                                ForEach(emptyTypes, id: \.self) { type in
                                    MeasurementEditCard(
                                        type: type,
                                        latest: latest(for: type),
                                        older: olderMeasurements(for: type)
                                    )
                                }
                            }
                        }
                        
                        // Кнопка создания нового параметра
                        Button(action: {
                            // TODO: Implement custom parameter creation
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Создать новый параметр")
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(DesignSystem.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.xl)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Замеры тела")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Measurement Edit Card

struct MeasurementEditCard: View {
    let type: MeasurementType
    let latest: BodyMeasurement?
    let older: [BodyMeasurement]
    
    @State private var showingAddMeasurement = false
    
    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(type.rawValue)
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                        .tracking(1.0)
                    
                    if let latest = latest {
                        // Текущее значение
                        Text("\(String(format: "%.1f", latest.value)) см")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        
                        // Старые значения (стопка)
                        if !older.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(older.enumerated()), id: \.element.date) { index, measurement in
                                    Text(String(format: "%.1f см", measurement.value))
                                        .font(DesignSystem.Typography.body())
                                        .strikethrough()
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .opacity(1.0 - (Double(index + 1) * 0.25))
                                }
                            }
                            .padding(.top, DesignSystem.Spacing.xs)
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: { showingAddMeasurement = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(measurementType: type)
        }
    }
}

#Preview {
    BodyMeasurementEditorView()
        .modelContainer(for: [BodyMeasurement.self], inMemory: true)
}
