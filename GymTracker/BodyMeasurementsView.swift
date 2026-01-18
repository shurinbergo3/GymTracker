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
                    // New Wide Header
                    WeightHeightHeader(
                        currentWeight: currentWeight,
                        previousWeight: previousWeight,
                        userProfile: currentProfile,
                        onAddWeight: { showingAddWeight = true },
                        onUpdateHeight: { showingAddProfile = true }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                        // Measurement Cards (Weight removed from here)
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
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
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
    
    private var previousWeight: Double? {
        // Index 1 is the previous record if it exists
        let history = weightHistory
        guard history.count > 1 else { return nil }
        return history[1].weight
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
        case .biceps: return "figure.strengthtraining.traditional"
        case .chest: return "tshirt.fill"
        case .waist: return "figure.stand"
        default: return "ruler.fill"
        }
    }
}

// MARK: - Weight & Height Header
struct WeightHeightHeader: View {
    let currentWeight: Double
    let previousWeight: Double?
    let userProfile: UserProfile?
    let onAddWeight: () -> Void
    let onUpdateHeight: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Weight Section (Left)
            Button(action: onAddWeight) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        Text("Вес")
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(.gray)
                    }
                    
                    Text(currentWeight > 0 ? String(format: "%.1f кг", currentWeight) : "—")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let prev = previousWeight {
                        Text("Было: \(String(format: "%.1f", prev))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("История пуста")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Height Section (Right)
            Button(action: onUpdateHeight) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lines.measurement.vertical")
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        Text("Рост")
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(.gray)
                    }
                    
                    if let profile = userProfile, profile.height > 0 {
                        Text("\(Int(profile.height)) см")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("Указать")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    
                    Text("Изменить")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.0)) // Spacer basically, keeping layout balanced
                        .accessibilityHidden(true)
                }
                .frame(width: 140, alignment: .leading)
                .padding()
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
}
