//
//  WorkoutProgressGraph.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Charts

struct WorkoutProgressGraph: View {
    let workoutDayName: String
    @Query private var allSessions: [WorkoutSession]
    
    private var historicalSessions: [WorkoutSession] {
        allSessions
            .filter { $0.workoutDayName == workoutDayName && $0.isCompleted }
            .sorted { $0.date < $1.date }
            .suffix(10) // Last 10 sessions
            .map { $0 }
    }
    
    private var volumeData: [(Date, Double)] {
        historicalSessions.map { session in
            let totalVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return (session.date, totalVolume)
        }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("ПРОГРЕСС ПО ОБЪЕМУ".localized())
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                if volumeData.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                            
                            Text("Нет данных для графика".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        Spacer()
                    }
                    .frame(height: 200)
                } else {
                    Chart {
                        ForEach(volumeData, id: \.0) { item in
                            LineMark(
                                x: .value("Дата".localized(), item.0),
                                y: .value("Объем".localized(), item.1)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Дата".localized(), item.0),
                                y: .value("Объем".localized(), item.1)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.neonGreen.opacity(0.3),
                                        DesignSystem.Colors.neonGreen.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            PointMark(
                                x: .value("Дата".localized(), item.0),
                                y: .value("Объем".localized(), item.1)
                            )
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                            .symbolSize(60)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption2)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                                .foregroundStyle(DesignSystem.Colors.secondaryText.opacity(0.2))
                            AxisValueLabel()
                                .font(.caption2)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("СРЕДНИЙ ОБЪЕМ".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            if !volumeData.isEmpty {
                                let avg = volumeData.map { $0.1 }.reduce(0, +) / Double(volumeData.count)
                                Text(String(format: "%.0f %@", avg, "кг".localized()))
                                    .font(DesignSystem.Typography.title3())
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                            Text("ТРЕНИРОВОК".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("\(historicalSessions.count)")
                                .font(DesignSystem.Typography.title3())
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    
    // Create sample sessions
    for i in 0..<5 {
        let session = WorkoutSession(workoutDayName: "Push")
        session.date = Calendar.current.date(byAdding: .day, value: -i * 3, to: Date())!
        session.isCompleted = true
        
        let set1 = WorkoutSet(exerciseName: "Bench Press", weight: Double(60 + i * 5), reps: 10)
        let set2 = WorkoutSet(exerciseName: "Bench Press", weight: Double(60 + i * 5), reps: 8)
        session.sets = [set1, set2]
        
        container.mainContext.insert(session)
    }
    
    return WorkoutProgressGraph(workoutDayName: "Push")
        .modelContainer(container)
        .background(DesignSystem.Colors.background)
}
