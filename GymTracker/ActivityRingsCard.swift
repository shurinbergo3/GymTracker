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
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Left: Rings
            ZStack {
                ActivityRingsView()
                    .frame(width: 130, height: 130)
            }
            .frame(width: 140)
            
            // Right: Text Details
            VStack(alignment: .leading, spacing: 12) {
                // Move (Red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подвижность")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Text("\(Int(move))/\(Int(moveGoal)) ККАЛ")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.2, blue: 0.4)) // Activity Red
                }
                
                // Exercise (Green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Упражнения")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Text("\(Int(exercise))/\(Int(exerciseGoal)) МИН")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.4, green: 1.0, blue: 0.2)) // Activity Green
                }
                
                // Stand (Blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("С разминкой")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Text("\(Int(stand))/\(Int(standGoal)) Ч")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.8, blue: 1.0)) // Activity Blue
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(Color(white: 0.1)) // Dark card background
        .cornerRadius(20)
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
