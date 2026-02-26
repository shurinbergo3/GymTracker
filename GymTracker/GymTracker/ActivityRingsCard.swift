//
//  ActivityRingsCard.swift
//  GymTracker
//
//  Created by Antigravity on 1/16/26.
//

import SwiftUI
import HealthKit

struct ActivityRingsCard: View {
    @State private var move: Double = 0
    @State private var moveGoal: Double = 600
    @State private var exercise: Double = 0
    @State private var exerciseGoal: Double = 30
    @State private var stand: Double = 0
    @State private var standGoal: Double = 12
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Left: Rings
            ZStack {
                ActivityRingsView()
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
            .frame(width: 130)
            
            // Right: Text Details
            VStack(alignment: .leading, spacing: 14) {
                // Move (Red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подвижность".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.0)
                    Text("\(Int(move))/\(Int(moveGoal))")
                        .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.4))
                    + Text(" " + "ккал".localized())
                        .font(DesignSystem.Typography.monospaced(.caption, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.4).opacity(0.7))
                }
                
                // Exercise (Green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Упражнения".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.0)
                    Text("\(Int(exercise))/\(Int(exerciseGoal))")
                        .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 1.0, blue: 0.2))
                    + Text(" " + "мин".localized())
                        .font(DesignSystem.Typography.monospaced(.caption, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 1.0, blue: 0.2).opacity(0.7))
                }
                
                // Stand (Blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("С разминкой".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.0)
                    Text("\(Int(stand))/\(Int(standGoal))")
                        .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 1.0))
                    + Text(" " + "ч".localized())
                        .font(DesignSystem.Typography.monospaced(.caption, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 1.0).opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)

        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            ActivityDetailView()
        }
        .onAppear {
            fetchActivityData()
        }
    }
    
    private func fetchActivityData() {
        Task {
            let summary = await HealthManager.shared.fetchActivitySummary()
            if let summary = summary {
                await MainActor.run {
                    self.move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
                    self.moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                    self.exercise = summary.appleExerciseTime.doubleValue(for: .minute())
                    self.exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                    self.stand = summary.appleStandHours.doubleValue(for: .count())
                    self.standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ActivityRingsCard()
            .frame(height: 200)
    }
}
