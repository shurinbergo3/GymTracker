//  CountdownView.swift
//  GymTracker
//
//  Apple Fitness-style countdown with premium animations and gradients
//

import SwiftUI
import AudioToolbox

struct CountdownView: View {
    var onComplete: () -> Void
    
    // State for animation phases
    @State private var count: Int = 3
    @State private var textPhase: String = "Get Ready..." // Starts with exact text from screenshot
    @State private var ringProgress: CGFloat = 0.0
    @State private var ringRotation: Double = 0.0
    @State private var numberScale: CGFloat = 0.5
    @State private var numberOpacity: Double = 0.0
    
    // Fancy gradients
    let ringGradient = AngularGradient(
        gradient: Gradient(colors: [
            DesignSystem.Colors.neonGreen.opacity(0.1),
            DesignSystem.Colors.neonGreen.opacity(0.4),
            DesignSystem.Colors.neonGreen
        ]),
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )
    
    var body: some View {
        ZStack {
            // 1. Deep OLED Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // 2. Main Center Content
            ZStack {
                // Outer Pulse Rings (Decorative)
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.1), lineWidth: 1)
                        .frame(width: 300 + CGFloat(i * 40), height: 300 + CGFloat(i * 40))
                        .scaleEffect(ringProgress > 0 ? 1.1 : 1.0)
                        .opacity(ringProgress > 0 ? 0.5 : 0.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: ringProgress)
                }
                
                // Track Ring (Background)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 16)
                    .frame(width: 220, height: 220)
                
                // Active Progress Ring
                if count > 0 {
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            ringGradient,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(ringRotation))
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 15)
                }
                
                // The Big Countdown Number
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 110, weight: .heavy, design: .rounded)) // Massive font
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.8), radius: 20)
                        .scaleEffect(numberScale)
                        .opacity(numberOpacity)
                } else {
                    // "GO" state or checkmark
                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                        .scaleEffect(numberScale)
                        .opacity(numberOpacity)
                }
            }
            .offset(y: -20)
            
            // 3. Text Label ("Get Ready..." -> "Exercise Name"?)
            VStack {
                Spacer()
                Text(textPhase)
                    .font(DesignSystem.Typography.title2())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .tracking(2) // Spaced out classy look
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            startSequence()
        }
    }
    
    private func startSequence() {
        // Start countdown immediately without "Get Ready" delay
        startCountdown()
    }
    
    private func startCountdown() {
        // Change text to motivational or exercise name
        withAnimation {
            textPhase = "Go!" // We will animate strictly on numbers now
        }
        
        // Loop 3 -> 1
        performCountStep(val: 3)
    }
    
    private func performCountStep(val: Int) {
        if val == 0 {
            finish()
            return
        }
        
        count = val
        textPhase = "Get Ready..." // Keep it simple or customize
        
        // Reset state for new number "pop"
        numberScale = 0.5
        numberOpacity = 0.0
        ringProgress = 0.0
        
        // 1. Animate Number In (Pop)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            numberScale = 1.2
            numberOpacity = 1.0
        }
        
        // 2. Animate Ring Fill (1 second duration)
        withAnimation(.easeInOut(duration: 0.9)) {
            ringProgress = 1.0
        }
        
        // 3. Sound & Haptics
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        AudioServicesPlaySystemSound(1113) // "Pew" sound
        
        // 4. Animate Number Out (Fade/Scale down) just before next
        withAnimation(.easeIn(duration: 0.2).delay(0.8)) {
            numberScale = 0.8
            numberOpacity = 0.0
        }
        
        // Schedule next step
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            performCountStep(val: val - 1)
        }
    }
    
    private func finish() {
        // GO!
        withAnimation(.spring()) {
            numberScale = 1.5
            numberOpacity = 1.0
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        AudioServicesPlaySystemSound(1057)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

#Preview {
    CountdownView(onComplete: {})
}
