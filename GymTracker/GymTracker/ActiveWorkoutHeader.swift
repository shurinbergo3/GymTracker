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

    private var totalTonnage: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        return session.sets
            .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
            .reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
    }

    private var liveCalories: Int { workoutManager.currentActiveCalories }

    var body: some View {
        // 1 Hz tick — sufficient for MM:SS display, friendly to battery.
        // Progress ring interpolates smoothly via .animation(.linear).
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            HStack(spacing: 12) {
                timerCapsule(context: context)

                Spacer(minLength: 6)

                metricPill(
                    icon: "heart.fill",
                    iconColor: .red,
                    value: "\(workoutManager.currentHeartRate)",
                    unit: "BPM".localized(),
                    animate: workoutManager.currentHeartRate
                )

                metricPill(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(liveCalories)",
                    unit: "KCAL".localized(),
                    animate: liveCalories
                )

                metricPill(
                    icon: "scalemass.fill",
                    iconColor: DesignSystem.Colors.neonGreen,
                    value: "\(totalTonnage)",
                    unit: "KG".localized(),
                    animate: totalTonnage
                )
            }
            .padding(.horizontal, 14)
            .frame(height: 70)
            .background(headerBackground)
            .overlay(
                Capsule()
                    .stroke(headerStroke, lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.18), radius: 14, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    // MARK: - Timer with progress ring (centerpiece)

    @ViewBuilder
    private func timerCapsule(context: TimelineView<PeriodicTimelineSchedule, Never>.Context) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 3.5)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: timerProgress(context.date))
                    .stroke(
                        AngularGradient(
                            colors: [
                                DesignSystem.Colors.neonGreen,
                                Color(red: 0.55, green: 0.95, blue: 0.10),
                                DesignSystem.Colors.neonGreen
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 44, height: 44)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.55), radius: 5)
                    .animation(.linear(duration: 1.0), value: context.date)

                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.7), radius: 3)
            }

            Text(formatTime(context.date))
                .font(DesignSystem.Typography.monospaced(.title2, weight: .heavy))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(0.5)
        }
    }

    @ViewBuilder
    private func metricPill(icon: String, iconColor: Color, value: String, unit: String, animate: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .shadow(color: iconColor.opacity(0.55), radius: 4)

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

    // MARK: - Background

    private var headerBackground: some View {
        ZStack {
            // Frosted base
            Capsule()
                .fill(.ultraThinMaterial)

            // Subtle dark tint to lift the glass off bright wallpapers
            Capsule()
                .fill(Color.black.opacity(0.25))

            // Neon glow accent in the top-left corner
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 180
            )
            .clipShape(Capsule())
        }
    }

    private var headerStroke: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.neonGreen.opacity(0.45),
                Color.white.opacity(0.08),
                DesignSystem.Colors.neonGreen.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Helpers

    private func timerProgress(_ date: Date) -> CGFloat {
        let elapsed: TimeInterval
        if let startDate = workoutManager.currentSession?.date {
            elapsed = date.timeIntervalSince(startDate)
        } else {
            elapsed = 0
        }

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
