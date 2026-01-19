//
//  RestTimerView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct RestTimerView: View {
    @Binding var isPresented: Bool
    let defaultDuration: Int // in seconds
    
    @State private var remainingTime: Int
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    
    init(isPresented: Binding<Bool>, defaultDuration: Int = 90) {
        self._isPresented = isPresented
        self.defaultDuration = defaultDuration
        self._remainingTime = State(initialValue: defaultDuration)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Bell icon + label compact
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                
                Text("Отдых")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize()
            }
            
            // Minus button
            Button(action: decreaseTime) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }
            .disabled(isRunning)
            .opacity(isRunning ? 0.3 : 1.0)
            
            // Time Display  
            Text(formatTime(remainingTime))
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(timeColor)
                .frame(minWidth: 75)
            
            // Plus button
            Button(action: increaseTime) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
            }
            .disabled(isRunning)
            .opacity(isRunning ? 0.3 : 1.0)
            
            Spacer()
            
            // Control Buttons
            if !isRunning {
                Button(action: startTimer) {
                    Text("СТАРТ")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.neonGreen)
                        .cornerRadius(18)
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: pauseTimer) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Button(action: skipTimer) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var timeColor: Color {
        if remainingTime <= 10 {
            return .red
        } else if remainingTime <= 30 {
            return .orange
        } else {
            return .white
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timerCompleted()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func skipTimer() {
        pauseTimer()
        isPresented = false
    }
    
    private func timerCompleted() {
        pauseTimer()
        
        // STRONG vibration pattern: 3 heavy taps + 2 very heavy (with intensity)
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
        heavyGenerator.prepare()
        rigidGenerator.prepare()
        
        // First heavy tap
        heavyGenerator.impactOccurred(intensity: 1.0)
        
        // Second heavy tap after 0.15s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            heavyGenerator.impactOccurred(intensity: 1.0)
            
            // Third heavy tap after 0.15s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heavyGenerator.impactOccurred(intensity: 1.0)
                
                // First VERY STRONG vibration after 0.3s pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    rigidGenerator.impactOccurred(intensity: 1.0)
                    
                    // Second VERY STRONG vibration after 0.4s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        rigidGenerator.impactOccurred(intensity: 1.0)
                        
                        // Third for extra emphasis
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            rigidGenerator.impactOccurred(intensity: 1.0)
                        }
                    }
                }
            }
        }
        
        // Auto-dismiss after all vibrations
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isPresented = false
        }
    }
    
    private func increaseTime() {
        remainingTime += 15
    }
    
    private func decreaseTime() {
        if remainingTime > 15 {
            remainingTime -= 15
        }
    }
}

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            RestTimerView(isPresented: .constant(true), defaultDuration: 90)
            Spacer()
        }
    }
}
