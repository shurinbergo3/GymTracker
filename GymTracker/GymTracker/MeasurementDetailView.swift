//
//  MeasurementDetailView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct MeasurementDetailView: View {
    let measurementType: MeasurementType
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeasurements: [BodyMeasurement]
    @State private var showingAddMeasurement = false
    
    private var measurements: [BodyMeasurement] {
        allMeasurements
            .filter { $0.type == measurementType }
            .sorted { $0.date > $1.date }
    }
    
    private var latestMeasurement: BodyMeasurement? {
        measurements.first
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Текущее значение
                if let latest = latestMeasurement {
                    CardView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Текущее значение".localized())
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text(String(format: "%.1f см", latest.value))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("Обновлено: \(latest.date.formatted(date: .long, time: .omitted))".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                } else {
                    CardView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "ruler")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("Нет данных".localized())
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Добавьте первое измерение".localized())
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // История
                if !measurements.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("История".localized())
                            .font(DesignSystem.Typography.title3())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(measurements, id: \.self) { measurement in
                                    MeasurementHistoryRow(measurement: measurement)
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, DesignSystem.Spacing.lg)
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddMeasurement = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(DesignSystem.Spacing.xl)
                }
            }
        }
        .navigationTitle(Text(measurementType.localizedName.localized()))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(measurementType: measurementType)
        }
    }
}

// MARK: - Measurement History Row

struct MeasurementHistoryRow: View {
    let measurement: BodyMeasurement
    
    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(measurement.date.formatted(date: .omitted, time: .shortened))
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                }
                
                Spacer()
                
                Text(String(format: "%.1f см", measurement.value))
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailView(measurementType: .biceps)
            .modelContainer(for: [BodyMeasurement.self], inMemory: true)
    }
}
