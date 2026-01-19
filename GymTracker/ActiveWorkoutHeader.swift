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
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 0.1)) { context in
            HStack(spacing: 0) {
                // 1. Digital Time & Circular Progress (Left)
                HStack(spacing: 12) {
                    ZStack {
                        // Background Ring
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            .frame(width: 50, height: 50)
                            
                        // Progress Ring (Visual loop effect for now, e.g. 60s loop)
                        Circle()
                            .trim(from: 0, to: timerProgress(context.date))
                            .stroke(
                                DesignSystem.Colors.neonGreen,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 50, height: 50)
                            .animation(.linear(duration: 0.1), value: context.date)
                        
                        // Play Icon or small indicator inside? 
                        // Request says "digital time inside" but 50px is too small for "24:15".
                        // Reference image shows large digital time inside a LARGE ring.
                        // Let's adjust layout to be one large container.
                    }
                    
                    Text(formatTime(context.date))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // 2. Heart Rate (Middle)
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(workoutManager.currentHeartRate)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("уд/мин")
                            .font(.system(size: 10)) // Fixed typo from 'sze'
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 3. Calories (Right)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(workoutManager.currentActiveCalories)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("ккал")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.trailing, 16)
            }
            .frame(height: 80)
            .background(Color(red: 0.1, green: 0.1, blue: 0.1)) // Dark grey background
            .cornerRadius(40) // Fully rounded pills
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, DesignSystem.Spacing.lg)
            // Cancel button moved out or overlay? Reference image doesn't show cancel.
            // We'll keep Cancel button available but discrete, maybe above?
            // Or usually "End" is at the bottom.
            // Requirement says "Replicate HUD style... Single wide dark rounded container".
            // I will add the Cancel 'X' as a small overlay on the top right OUTSIDE or just tap header to open menu?
            // Let's keep the discrete X button from previous design but positioned nicely if needed.
            // Actually, usually headers are just data.
        }
    }
    
    private func timerProgress(_ date: Date) -> CGFloat {
        // Visual effect: Loop every 60 seconds based on ELAPSED time
        let elapsed: TimeInterval
        if let startDate = workoutManager.currentSession?.date {
            elapsed = date.timeIntervalSince(startDate)
        } else {
            elapsed = 0
        }
        
        // Calculate progress within current minute (0.0 to 1.0)
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
        
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
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
