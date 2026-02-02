//
//  ExerciseProgressRow.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct ExerciseProgressRow: View {
    let exerciseProgress: ExerciseProgress
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Exercise name
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(exerciseProgress.exerciseName)
                    .font(DesignSystem.Typography.callout())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                // Stats comparison
                if let previousStats = exerciseProgress.previousStats {
                    HStack(spacing: 4) {
                        Text(previousStats)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .strikethrough()
                        
                        Text("→")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(exerciseProgress.currentStats)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(exerciseProgress.progressState.color)
                            .fontWeight(.semibold)
                    }
                } else {
                    Text(exerciseProgress.currentStats)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Progress icon
            Image(systemName: exerciseProgress.progressState.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(exerciseProgress.progressState.color)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        ExerciseProgressRow(
            exerciseProgress: ExerciseProgress(
                exerciseName: "Жим лежа",
                progressState: .improved,
                currentStats: "80 кг",
                previousStats: "75 кг"
            )
        )
        
        ExerciseProgressRow(
            exerciseProgress: ExerciseProgress(
                exerciseName: "Приседания",
                progressState: .declined,
                currentStats: "100 кг",
                previousStats: "110 кг"
            )
        )
        
        ExerciseProgressRow(
            exerciseProgress: ExerciseProgress(
                exerciseName: "Становая тяга",
                progressState: .same,
                currentStats: "120 кг",
                previousStats: "120 кг"
            )
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
