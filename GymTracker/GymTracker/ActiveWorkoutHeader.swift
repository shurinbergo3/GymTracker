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

    // MARK: - Derived metrics

    private var totalTonnage: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        return session.sets
            .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
            .reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
    }

    private var liveCalories: Int { workoutManager.currentActiveCalories }

    private var completedSetsCount: Int {
        workoutManager.currentSession?.sets.filter { $0.isCompleted }.count ?? 0
    }

    private var totalPlannedSets: Int {
        guard let day = workoutManager.selectedDay else { return 0 }
        return day.exercises
            .filter { $0.modelContext != nil }
            .reduce(0) { $0 + max(1, $1.plannedSets) }
    }

    /// Ring fill — real workout completion (sets done / planned). Replaces the
    /// old per-minute cycle that conveyed nothing. Falls back to 0 with no plan.
    private var sessionProgress: CGFloat {
        guard totalPlannedSets > 0 else { return 0 }
        return min(1, CGFloat(completedSetsCount) / CGFloat(totalPlannedSets))
    }

    /// Session XP — each completed set is +10 XP. Purely motivational; ticks up
    /// live with a "+N XP" readout so progress is felt in the moment.
    private var sessionXP: Int { completedSetsCount * 10 }

    /// Current combo — trailing run of sets logged within 4 min of each other.
    /// A longer rest resets it. Rewards keeping the tempo, without punishment.
    private var combo: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        let done = session.sets.filter { $0.isCompleted }.sorted { $0.date < $1.date }
        guard done.count >= 1 else { return 0 }
        var run = 1
        var i = done.count - 1
        while i > 0 {
            let gap = done[i].date.timeIntervalSince(done[i - 1].date)
            if gap <= 240 { run += 1; i -= 1 } else { break }
        }
        return run
    }

    /// Heart-rate zone tint by absolute bpm (recovery → effort → peak). When
    /// there's no live reading (0) the icon reads muted rather than alarming red.
    private var hrZoneColor: Color {
        let hr = workoutManager.currentHeartRate
        switch hr {
        case ..<1:        return DesignSystem.Colors.secondaryText
        case 1..<100:     return Color(red: 0.40, green: 0.80, blue: 1.0)   // light effort
        case 100..<140:   return DesignSystem.Colors.neonGreen              // cardio
        case 140..<170:   return .orange                                    // hard
        default:          return Color(red: 1.0, green: 0.30, blue: 0.35)   // peak
        }
    }

    // MARK: - Body

    var body: some View {
        // 1 Hz tick — drives only the MM:SS readout. The ring tracks set
        // progress (state-driven), so it animates on completion, not per second.
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    progressRing(date: context.date)

                    VStack(spacing: 9) {
                        statRow(icon: "heart.fill", color: hrZoneColor,
                                value: "\(workoutManager.currentHeartRate)", unit: "BPM".localized(),
                                animate: workoutManager.currentHeartRate)
                        statRow(icon: "flame.fill", color: .orange,
                                value: "\(liveCalories)", unit: "KCAL".localized(),
                                animate: liveCalories)
                        statRow(icon: "scalemass.fill", color: DesignSystem.Colors.neonGreen,
                                value: "\(totalTonnage)", unit: "KG".localized(),
                                animate: totalTonnage)
                    }
                }

                impulseBar
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(heroBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(headerStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.18), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 8)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    // MARK: - Progress ring (centerpiece — time in center, sets as fill)

    @ViewBuilder
    private func progressRing(date: Date) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .frame(width: 88, height: 88)

            Circle()
                .trim(from: 0, to: sessionProgress)
                .stroke(
                    LinearGradient(
                        colors: [DesignSystem.Colors.neonGreen, Color(red: 0.33, green: 0.88, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 88, height: 88)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.55), radius: 5)
                .animation(.easeOut(duration: 0.4), value: sessionProgress)

            VStack(spacing: 1) {
                Text(formatTime(date))
                    .font(DesignSystem.Typography.monospaced(.headline, weight: .heavy))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .kerning(0.5)
                Text("\(completedSetsCount)/\(totalPlannedSets)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(width: 96, height: 96)
    }

    // MARK: - Live stat row

    @ViewBuilder
    private func statRow(icon: String, color: Color, value: String, unit: String, animate: Int) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
                .shadow(color: color.opacity(0.5), radius: 4)

            Text(value)
                .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.35), value: animate)

            Text(unit)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(0.8)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Session impulse (live XP + combo)

    private var impulseBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.neonGreen, Color(red: 0.33, green: 0.88, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * sessionProgress))
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 5)
                        .animation(.easeOut(duration: 0.35), value: sessionProgress)
                }
            }
            .frame(height: 7)

            if combo >= 2 {
                comboChip
                    .transition(.scale.combined(with: .opacity))
            }

            Text("+\(sessionXP) XP")
                .font(DesignSystem.Typography.monospaced(.caption, weight: .heavy))
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.35), value: sessionXP)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: combo)
    }

    private var comboChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 9, weight: .black))
            Text("×\(combo)")
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(Capsule())
        .shadow(color: Color.red.opacity(0.5), radius: 6)
    }

    // MARK: - Background

    private var heroBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.25))
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.16), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 240
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
