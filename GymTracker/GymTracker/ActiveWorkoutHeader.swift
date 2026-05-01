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
        return session.sets
            .filter { $0.isCompleted && $0.isWeighted }
            .reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        // Раньше было 0.1с (10 Hz) — это перерисовывало весь header 10 раз в секунду
        // и было главным источником разряда батареи во время активной тренировки.
        // 1.0с достаточно для таймера MM:SS, а кольцо прогресса плавно интерполируется
        // через .animation(.linear(duration: 1.0)).
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            HStack(spacing: 20) {
                // 1. Digital Time (Left)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            .frame(width: 44, height: 44)
                            
                        Circle()
                            .trim(from: 0, to: timerProgress(context.date))
                            .stroke(
                                DesignSystem.Colors.neonGreen,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 4)
                            .animation(.linear(duration: 1.0), value: context.date)
                        
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                    
                    Text(formatTime(context.date))
                        .font(DesignSystem.Typography.monospaced(.title2, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                // 2. Heart Rate (Middle)
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.5), radius: 5)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(workoutManager.currentHeartRate)")
                            .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Text("BPM".localized())
                            .font(DesignSystem.Typography.sectionHeader())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.0)
                    }
                }
                
                Spacer()
                
                // 3. Tonnage (Right) — личная история «сколько я поднял»
                HStack(spacing: 8) {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 5)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(totalTonnage)")
                            .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .contentTransition(.numericText())
                            .animation(.easeOut(duration: 0.35), value: totalTonnage)
                        Text("KG".localized())
                            .font(DesignSystem.Typography.sectionHeader())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 74)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(40) // Pill shape for header
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
            .padding(.horizontal, DesignSystem.Spacing.lg)
    
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
 