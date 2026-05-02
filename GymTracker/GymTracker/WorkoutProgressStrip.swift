//
//  WorkoutProgressStrip.swift
//  GymTracker
//
//  Real-time gamification strip shown during an active workout.
//  Displays segmented set-progress, streak chip, and a PR flash overlay.
//

import SwiftUI
import SwiftData

struct WorkoutProgressStrip: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var pulse: Bool = false
    @State private var prFlashActive: Bool = false

    private var totalPlannedSets: Int {
        guard let day = workoutManager.selectedDay else { return 0 }
        return day.exercises.reduce(0) { $0 + max(1, $1.plannedSets) }
    }

    private var completedSets: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        return session.sets.filter { $0.isCompleted }.count
    }

    private var progress: Double {
        guard totalPlannedSets > 0 else { return 0 }
        return min(1.0, Double(completedSets) / Double(totalPlannedSets))
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.currentLocale
        cal.firstWeekday = 2
        return cal
    }

    private var trainedDays: Set<Date> {
        let cal = calendar
        return Set(allSessions.map { cal.startOfDay(for: $0.date) })
    }

    private var currentStreak: Int {
        let cal = calendar
        var current = cal.startOfDay(for: Date())
        var count = 0
        if !trainedDays.contains(current) {
            guard let y = cal.date(byAdding: .day, value: -1, to: current) else { return 0 }
            current = y
        }
        while trainedDays.contains(current) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return count
    }

    var body: some View {
        VStack(spacing: 10) {
            topRow
            bottomRow
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(stripBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(prFlashActive ? Color.yellow.opacity(0.85) : DesignSystem.Colors.neonGreen.opacity(0.18), lineWidth: prFlashActive ? 2 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .shadow(color: prFlashActive ? Color.yellow.opacity(0.5) : DesignSystem.Colors.neonGreen.opacity(0.10),
                radius: prFlashActive ? 18 : 10, x: 0, y: 4)
        .overlay(prOverlay)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .scaleEffect(pulse ? 1.015 : 1.0)
        .animation(.spring(response: 0.32, dampingFraction: 0.55), value: pulse)
        .onChange(of: workoutManager.setCompletionTick) { _, _ in
            triggerPulse()
        }
        .onChange(of: workoutManager.prFlashTrigger) { _, _ in
            triggerPRFlash()
        }
    }

    // MARK: - Top row: segmented progress bar + count

    private var topRow: some View {
        HStack(spacing: 12) {
            segmentedBar
                .frame(maxWidth: .infinity)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(completedSets)")
                    .font(DesignSystem.Typography.monospaced(.title3, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("/ \(totalPlannedSets)")
                    .font(DesignSystem.Typography.monospaced(.subheadline, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            .frame(minWidth: 56, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var segmentedBar: some View {
        if totalPlannedSets == 0 {
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 8)
        } else if totalPlannedSets <= 16 {
            HStack(spacing: 3) {
                ForEach(0..<totalPlannedSets, id: \.self) { idx in
                    Group {
                        if idx < completedSets {
                            RoundedRectangle(cornerRadius: 3).fill(filledStyle)
                        } else {
                            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08))
                        }
                    }
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
                    .shadow(color: idx < completedSets ? DesignSystem.Colors.neonGreen.opacity(0.5) : .clear,
                            radius: 3)
                    .animation(.easeOut(duration: 0.25), value: completedSets)
                }
            }
        } else {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(filledStyle)
                        .frame(width: max(8, geo.size.width * progress))
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 4)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    private var filledStyle: LinearGradient {
        LinearGradient(
            colors: [DesignSystem.Colors.neonGreen, Color(red: 0.55, green: 0.95, blue: 0.10)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Bottom row: chips

    private var bottomRow: some View {
        HStack(spacing: 10) {
            statusChip
            Spacer()
            if currentStreak > 0 {
                streakChip
            }
        }
    }

    private var statusChip: some View {
        HStack(spacing: 6) {
            Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "bolt.fill")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(progress >= 1.0 ? DesignSystem.Colors.neonGreen : Color.yellow)
            Text(statusText)
                .font(DesignSystem.Typography.sectionHeader())
                .tracking(0.8)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
    }

    private var statusText: String {
        if totalPlannedSets == 0 {
            return "В работе".localized().uppercased()
        }
        if progress >= 1.0 {
            return "Готово!".localized().uppercased()
        }
        let remaining = totalPlannedSets - completedSets
        return String(format: "ещё %d".localized(), remaining).uppercased()
    }

    private var streakChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(colors: [Color.orange, Color.red.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                )
            Text("\(currentStreak)")
                .font(DesignSystem.Typography.monospaced(.subheadline, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text(dayShort(currentStreak))
                .font(DesignSystem.Typography.sectionHeader())
                .tracking(0.6)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.orange.opacity(0.35), lineWidth: 0.5))
    }

    // MARK: - PR overlay

    @ViewBuilder
    private var prOverlay: some View {
        if prFlashActive {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color.yellow)
                Text("Новый рекорд!".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(Color.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.65))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
            .shadow(color: Color.yellow.opacity(0.45), radius: 10)
            .offset(y: -32)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    // MARK: - Background

    private var stripBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.13, blue: 0.10),
                    Color(red: 0.05, green: 0.07, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 220
            )
            if prFlashActive {
                RadialGradient(
                    colors: [Color.yellow.opacity(0.25), .clear],
                    center: .center,
                    startRadius: 4,
                    endRadius: 260
                )
            }
        }
    }

    // MARK: - Animations

    private func triggerPulse() {
        pulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            pulse = false
        }
    }

    private func triggerPRFlash() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            prFlashActive = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                prFlashActive = false
            }
        }
    }

    // MARK: - Helpers

    private func dayShort(_ value: Int) -> String {
        let mod10 = value % 10
        let mod100 = value % 100
        if mod10 == 1 && mod100 != 11 {
            return "день".localized()
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "дня".localized()
        } else {
            return "дней".localized()
        }
    }
}
