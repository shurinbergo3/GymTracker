//  CountdownView.swift
//  GymTracker
//
//  Apple Fitness-style countdown with animated ring

import SwiftUI

struct CountdownView: View {
    var onComplete: () -> Void
    
    @State private var countdown = 3
    @State private var progress: CGFloat = 0.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Ring with Countdown Number
                ZStack {
                    // Background Circle (dim)
                    Circle()
                        .stroke(
                            DesignSystem.Colors.neonGreen.opacity(0.2),
                            lineWidth: 12
                        )
                        .frame(width: 240, height: 240)
                    
                    // Animated Progress Ring (full circle, rotating)
                    Circle()
                        .trim(from: 0, to: 1.0)
                        .stroke(
                            DesignSystem.Colors.neonGreen,
                            style: StrokeStyle(
                                lineWidth: 12,
                                lineCap: .round
                            )
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(progress * 360 - 90.0)) // Rotate full 360° per second
                        .animation(.linear(duration: 1.0), value: progress)
                    
                    // Countdown Number
                    if countdown > 0 {
                        Text("\(countdown)")
                            .font(.system(size: 100, weight: .bold, design: .rounded))
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                            .scaleEffect(scale)
                    } else {
                        Text("GO!")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                            .scaleEffect(scale)
                    }
                }
                
                // "Ready" text below
                Text(countdown > 0 ? "Готовьтесь..." : "Начинаем!")
                    .font(DesignSystem.Typography.title2())
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 20)
                
                Spacer()
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private func startCountdown() {
        // Kick off the countdown sequence
        performCountdownStep()
    }
    
    private func performCountdownStep() {
        // Animate ring filling for this second
        withAnimation(.easeInOut(duration: 1.0)) {
            progress = 1.0
        }
        
        // Pulse scale animation
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.3
        }
        
        // Reset scale
        withAnimation(.easeIn(duration: 0.2).delay(0.3)) {
            scale = 1.0
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // After 1 second, move to next count or complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            countdown -= 1
            
            if countdown >= 0 {
                // Reset progress for next ring animation
                progress = 0.0
                performCountdownStep()
            } else {
                // Countdown complete - trigger onComplete
                withAnimation {
                    scale = 0.8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    CountdownView {
        print("Countdown complete!")
    }
}
