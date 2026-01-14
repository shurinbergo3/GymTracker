//
//  BodyMeasurementsView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct BodyMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    
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
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                        // Weight Card
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
                        
                        // Measurement Cards
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
        }
        .navigationTitle("Замеры тела")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddProfile) {
            CreateProfileView()
        }
        .sheet(isPresented: $showingAddWeight) {
            if let profile = currentProfile {
                AddWeightView(userProfile: profile)
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
        switch type {
        case .biceps: return "arm"
        case .chest: return "tshirt.fill"
        case .waist: return "figure.stand"
        default: return "ruler.fill"
        }
    }
}
