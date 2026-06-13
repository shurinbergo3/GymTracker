//
//  RestTimerView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import UserNotifications

struct RestTimerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var isPresented: Bool
    let defaultDuration: Int // in seconds
    let autoStart: Bool // whether to auto-start timer

    @State private var remainingTime: Int
    @State private var isRunning: Bool = false
    @State private var timer: Timer?

    init(isPresented: Binding<Bool>, defaultDuration: Int = 90, autoStart: Bool = false) {
        self._isPresented = isPresented
        self.defaultDuration = defaultDuration
        self.autoStart = autoStart
        self._remainingTime = State(initialValue: defaultDuration)
    }

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        HStack(spacing: 12) {
            // Bell icon + label compact
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.neonGreen)

                Text("Отдых".localized())
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
                    Text("СТАРТ".localized())
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.neonGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { _, _ in }
            if autoStart && !isRunning {
                startTimer()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                if isRunning {
                    // Stop the UI tick to save CPU; the absolute end date
                    // (workoutManager.restEndsAt) remains the source of truth,
                    // so no elapsed time is lost while backgrounded.
                    timer?.invalidate()
                    timer = nil
                    scheduleNotification()
                }
            } else if newPhase == .active {
                if isRunning {
                    cancelNotification()
                    // Recompute purely from the absolute end date — robust to
                    // any amount of time spent in the background.
                    syncRemainingFromEndDate()
                    if isRunning { startTick() }
                }
            }
        }

        .onReceive(NotificationCenter.default.publisher(
            for: WatchSyncBridge.watchActionNotification
        )) { note in
            guard (note.userInfo?["action"] as? String) == "skipRest" else { return }
            // Mirror the iPhone-side forward-button tap so haptics / cleanup
            // run through the same code path. Safe to call even if the timer
            // hasn't started yet — pauseTimer() just clears state.
            skipTimer()
        }

        .onDisappear {
            // Ensure timer is stopped when view is removed
            timer?.invalidate()
            timer = nil
            cancelNotification()
            workoutManager.clearRest()
        }
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
        // If timer finished (0), restart it from default duration
        if remainingTime <= 0 {
            remainingTime = defaultDuration
        }

        isRunning = true
        // Push the running rest end into the WorkoutManager. `restEndsAt`
        // (an absolute Date) is the single source of truth — it drives the
        // Live Activity, the Apple Watch, AND the local countdown below.
        workoutManager.beginRest(duration: TimeInterval(remainingTime))
        startTick()
    }

    /// Starts (or restarts) the 1-second UI tick. The tick does NOT decrement a
    /// counter — it re-derives `remainingTime` from the absolute end date every
    /// fire, so dropped ticks (RunLoop busy with scrolling/animation) and
    /// backgrounding never cause drift.
    private func startTick() {
        timer?.invalidate()
        // `.common` mode keeps the tick firing during scroll/animation tracking.
        let t = Timer(timeInterval: 0.5, repeats: true) { _ in
            syncRemainingFromEndDate()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Re-derives the displayed remaining seconds from `restEndsAt` and finishes
    /// when the absolute end date has passed.
    private func syncRemainingFromEndDate() {
        guard let endDate = workoutManager.restEndsAt else {
            // Rest was cleared elsewhere (skip / new set). Stop ticking.
            timer?.invalidate()
            timer = nil
            isRunning = false
            return
        }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            remainingTime = 0
            timerCompleted()
        } else {
            remainingTime = Int(remaining.rounded(.up))
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        workoutManager.clearRest()
    }

    private func skipTimer() {
        pauseTimer()
        isPresented = false
    }

    private func timerCompleted() {
        pauseTimer()

        // Strong haptic-only finish — NO sound (per user rule, audio would
        // interrupt the user's headphone music).
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
        heavyGenerator.prepare()
        rigidGenerator.prepare()

        // Pattern: 3 heavy taps + 3 rigid taps, all at full intensity.
        heavyGenerator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            heavyGenerator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heavyGenerator.impactOccurred(intensity: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    rigidGenerator.impactOccurred(intensity: 1.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        rigidGenerator.impactOccurred(intensity: 1.0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            rigidGenerator.impactOccurred(intensity: 1.0)
                        }
                    }
                }
            }
        }

        // Auto-dismiss after the haptics finish.
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

    // MARK: - Notification Helpers
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Время отдыха вышло!".localized()
        content.body = "Пора приступать к следующему подходу".localized()
        // Sound deliberately omitted — see RestTimerView haptic-only rule.
        // The system still delivers a banner haptic + the watch app fires
        // its own rich haptic when the mirrored rest timer expires.
        content.sound = nil
        if #available(iOS 15.0, *) {
            // Wakes the device past Focus modes so the haptic is delivered
            // promptly even if the user has notifications muted by default.
            content.interruptionLevel = .timeSensitive
        }

        // Fire exactly when the absolute end date is reached, not after a
        // counter that may have drifted.
        let triggerTime = workoutManager.restEndsAt?.timeIntervalSinceNow ?? Double(remainingTime)
        if triggerTime > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            let request = UNNotificationRequest(identifier: "RestTimerDone", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["RestTimerDone"])
    }
}

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack {
            Spacer()
            RestTimerView(isPresented: .constant(true), defaultDuration: 90, autoStart: false)
            Spacer()
        }
    }
}
