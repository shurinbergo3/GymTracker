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
    @Binding var showingCancelConfirmation: Bool
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.1)) { context in
            VStack(spacing: DesignSystem.Spacing.md) {
                // Top Row: Title & Cancel
                HStack {
                    Text("Тренировка")
                        .font(DesignSystem.Typography.largeTitle())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Button(action: { showingCancelConfirmation = true }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                
                // Bento Grid Data
                HStack(spacing: 12) {
                    // Main Timer Card (Takes 50% width)
                    HeaderBentoCard(color: DesignSystem.Colors.cardBackground) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("ВРЕМЯ")
                                    .font(DesignSystem.Typography.caption())
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Text(formatTime(context.date))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    
                    // Right Column (2 stacked small cards)
                    VStack(spacing: 12) {
                        // Pulse & Calories Row
                        HStack(spacing: 12) {
                            // Pulse
                            HeaderBentoCard(color: Color.red.opacity(0.15)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    
                                    Text("\(workoutManager.currentHeartRate)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("BPM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            // Calories
                            HeaderBentoCard(color: Color.orange.opacity(0.15)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("\(workoutManager.currentActiveCalories)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("KCAL")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .frame(height: 70)
                        
                        // Progress Bar / Metric
                        HeaderBentoCard(color: DesignSystem.Colors.cardBackground) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ПРОГРЕСС")
                                        .font(DesignSystem.Typography.caption())
                                        .fontWeight(.bold)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text("Отличный темп")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                }
                                
                                Spacer()
                                
                                // Arrow Icon
                                Image(systemName: "arrow.up.right")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .padding(8)
                                    .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .frame(height: 50)
                    }
                }
                .frame(height: 140) // Fixed height for the grid
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    private func formatTime(_ currentDate: Date) -> String {
        let elapsed: TimeInterval
        if let startDate = workoutManager.currentSession?.date {
            elapsed = currentDate.timeIntervalSince(startDate)
        } else {
            elapsed = 0
        }
        
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        let centiseconds = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
        } else {
            return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
        }
    }
}
// Simple Helper for Bento Cards within this header
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
