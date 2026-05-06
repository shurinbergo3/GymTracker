//
//  ActiveWorkoutHeader.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import Combine

struct ActiveWorkoutHeader: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    // Timer properties
    @State private var progress: CGFloat = 0.0
    
    private var totalTonnage: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        // Считаем тоннаж по ЛЮБЫМ выполненным подходам с весом > 0,
        // не только по флагу isWeighted (он включается лишь для bodyweight+вес,
        // из-за чего обычные силовые показывали 0 KG).
        return session.sets
            .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
            .reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
    }

    private var liveCalories: Int { workoutManager.currentActiveCalories }
    
    var body: some View {
        // Раньше было 0.1с (10 Hz) — это перерисовывало весь header 10 раз в секунду
        // и было главным источником разряда батареи во время активной тренировки.
        // 1.0с достаточно для таймера MM:SS, а кольцо прогресса плавно интерполируется
        // через .animation(.linear(duration: 1.0)).
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            HStack(spacing: 14) {
                // 1. Digital Time (Left)
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 40, height: 40)

                        Circle()
                            .trim(from: 0, to: timerProgress(context.date))
                            .stroke(
                                DesignSystem.Colors.neonGreen,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 40, height: 40)
                            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 4)
                            .animation(.linear(duration: 1.0), value: context.date)

                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }

                    Text(formatTime(context.date))
                        .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }

                Spacer(minLength: 4)

                // 2. Heart Rate
                metricPill(
                    icon: "heart.fill",
                    iconColor: .red,
                    value: "\(workoutManager.currentHeartRate)",
                    unit: "BPM".localized(),
                    animate: workoutManager.currentHeartRate
                )

                // 3. Calories — live (HK + HR-fallback)
                metricPill(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(liveCalories)",
                    unit: "KCAL".localized(),
                    animate: liveCalories
                )

                // 4. Tonnage
                metricPill(
                    icon: "scalemass.fill",
                    iconColor: DesignSystem.Colors.neonGreen,
                    value: "\(totalTonnage)",
                    unit: "KG".localized(),
                    animate: totalTonnage
                )
            }
            .padding(.horizontal, 16)
            .frame(height: 74)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(40) // Pill shape for header
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    @ViewBuilder
    private func metricPill(icon: String, iconColor: Color, value: String, unit: String, animate: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .shadow(color: iconColor.opacity(0.5), radius: 4)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.35), value: animate)
                Text(unit)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(0.8)
            }
        }
    }
    
    private func timerProgress(_ date: Date) -> CGFloat {
        let elapsed: TimeInterval
        if let startDate = workoutManager.currentSession?.date {
            elapsed = date.timeIntervalSince(startDate)
        } else {
            elapsed = 0
        }
        
        // Return 0 if negative to avoid crashes/weird UI
        if elapsed < 0 { return 0 }
        
        let secondsInMinute = elapsed.truncatingRemainder(dividingBy: 60)
        return CGFloat(secondsInMinute) / 60.0
    }
    
    private func formatTime(_ currentDate: Date) -> String {
        let elapsed: TimeInterval
        if let startDate = workoutManager.currentSession?.date {
            elapsed = currentDate.timeIntervalSince(startDate)
        } else {
            elapsed = 0
        }
        
        if elapsed < 0 { return "00:00" }
        
        let totalSeconds = Int(elapsed)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Simple Helper for Bento Cards (Re-added for compatibility)
struct HeaderBentoCard<Content: View>: View {
    let color: Color
    let content: Content
    
    init(color: Color = DesignSystem.Colors.cardBackground, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            color
            
            content
                .padding(12)
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
 