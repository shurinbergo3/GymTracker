//
//  ActiveWorkoutHeader.swift
//  GymTracker
//
//  Created by Antigravity
//
//  Single dense live HUD: time + set progress, live metrics (HR/kcal/tonnage),
//  a session-momentum bar, day-streak and combo. Folds in what used to be a
//  separate WorkoutProgressStrip (streak / status / PR-flash) so the active
//  screen reads as one compact card with no wasted side space.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutHeader: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var prFlashActive = false
    @State private var prFlashResetWork: DispatchWorkItem?
    @State private var pulse = false
    @State private var pulseResetWork: DispatchWorkItem?

    // MARK: - Streak

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

    // MARK: - Live metrics

    private var totalTonnage: Int {
        guard let session = workoutManager.currentSession else { return 0 }
        return session.sets
            .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
            .reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
    }

    /// Tonnage shrinks to tonnes once it passes 1000 kg so the number stays short
    /// and the row never overflows (matches the "т" abbreviation used elsewhere).
    private var tonnageValue: String {
        totalTonnage >= 1000 ? String(format: "%.1f", Double(totalTonnage) / 1000.0) : "\(totalTonnage)"
    }
    private var tonnageUnit: String {
        totalTonnage >= 1000 ? "т".localized() : "кг".localized()
    }

    private var liveCalories: Int { workoutManager.currentActiveCalories }

    private var hrValue: String {
        workoutManager.currentHeartRate > 0 ? "\(workoutManager.currentHeartRate)" : "–"
    }

    private var completedSetsCount: Int {
        workoutManager.currentSession?.sets.filter { $0.isCompleted }.count ?? 0
    }

    private var totalPlannedSets: Int {
        guard let day = workoutManager.selectedDay else { return 0 }
        return day.exercises
            .filter { $0.modelContext != nil }
            .reduce(0) { $0 + max(1, $1.plannedSets) }
    }

    private var sessionProgress: CGFloat {
        guard totalPlannedSets > 0 else { return 0 }
        return min(1, CGFloat(completedSetsCount) / CGFloat(totalPlannedSets))
    }

    /// Session XP — each completed set is +10 XP. Motivational; ticks up live.
    private var sessionXP: Int { completedSetsCount * 10 }

    /// Combo — trailing run of sets logged within 4 min of each other. A longer
    /// rest resets it. Rewards tempo, never punishes.
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

    /// Heart-rate zone tint by absolute bpm. No reading (0) → muted, not alarming.
    private var hrZoneColor: Color {
        let hr = workoutManager.currentHeartRate
        switch hr {
        case ..<1:      return DesignSystem.Colors.secondaryText
        case 1..<100:   return Color(red: 0.40, green: 0.80, blue: 1.0)
        case 100..<140: return DesignSystem.Colors.neonGreen
        case 140..<170: return .orange
        default:        return Color(red: 1.0, green: 0.30, blue: 0.35)
        }
    }

    // MARK: - Body

    var body: some View {
        card
            .overlay(alignment: .top) { prOverlay }
            .scaleEffect(pulse ? 1.012 : 1.0)
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.16), radius: 14, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .animation(.spring(response: 0.32, dampingFraction: 0.55), value: pulse)
            .onChange(of: workoutManager.setCompletionTick) { _, _ in triggerPulse() }
            .onChange(of: workoutManager.prFlashTrigger) { _, _ in triggerPRFlash() }
            .onDisappear {
                // Cancel any pending reset so it can't fire on a torn-down view
                // and leave stale pulse/PR-flash state if the header reappears.
                pulseResetWork?.cancel()
                prFlashResetWork?.cancel()
            }
    }

    private var card: some View {
        // The 1 Hz tick is scoped to ONLY the MM:SS readout (see `timeReadout`).
        // Everything here — set-progress, streak, combo, tonnage — is state-driven,
        // so this VStack recomputes on data change, not every second.
        VStack(spacing: 13) {
            topRow
            momentumRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(heroBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(headerStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Top row: time + sets | live metrics

    /// Only the elapsed-time label needs the 1 Hz tick — isolating it here keeps
    /// the rest of the card (streak/combo/tonnage) off the per-second render path.
    private var timeReadout: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            Text(formatTime(context.date))
                .font(.system(size: 33, weight: .heavy, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .kerning(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                timeReadout
                Text("\(completedSetsCount) / \(totalPlannedSets) \("подходов".localized())")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 16) {
                metricCol(icon: "heart.fill", color: hrZoneColor,
                          value: hrValue, unit: "уд/мин".localized(),
                          animate: workoutManager.currentHeartRate)
                metricCol(icon: "flame.fill", color: .orange,
                          value: "\(liveCalories)", unit: "ккал".localized(),
                          animate: liveCalories)
                metricCol(icon: "scalemass.fill", color: DesignSystem.Colors.neonGreen,
                          value: tonnageValue, unit: tonnageUnit,
                          animate: totalTonnage)
            }
        }
    }

    @ViewBuilder
    private func metricCol(icon: String, color: Color, value: String, unit: String, animate: Int) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.35), value: animate)

            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .tracking(0.2)
            }
        }
        .fixedSize()
    }

    // MARK: - Momentum row: streak | progress | combo | XP

    private var momentumRow: some View {
        HStack(spacing: 8) {
            if currentStreak > 0 { streakChip }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.09))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.neonGreen, Color(red: 0.33, green: 0.88, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * sessionProgress)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 5)
                        .animation(.easeOut(duration: 0.35), value: sessionProgress)
                }
            }
            .frame(height: 7)
            .frame(maxWidth: .infinity)

            if combo >= 2 {
                comboChip
                    .transition(.scale.combined(with: .opacity))
            }

            Text("+\(sessionXP) XP")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.35), value: sessionXP)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: combo)
    }

    /// Day-streak — flame, left of the bar. Cross-session (distinct from combo).
    private var streakChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .black))
            Text("\(currentStreak)")
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.orange.opacity(0.30), lineWidth: 0.5))
    }

    /// Combo — bolt (NOT flame), right of the bar, so it never reads as the streak.
    private var comboChip: some View {
        HStack(spacing: 2) {
            Image(systemName: "bolt.fill")
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
        .shadow(color: Color.red.opacity(0.45), radius: 5)
    }

    // MARK: - PR flash (folded in from the old strip)

    @ViewBuilder
    private var prOverlay: some View {
        if prFlashActive {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.yellow)
                Text("Новый рекорд!".localized())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
            .shadow(color: Color.yellow.opacity(0.45), radius: 10)
            .offset(y: -18)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    // MARK: - Background

    private var heroBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.25))
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.16), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 240
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    // MARK: - Animations

    private func triggerPulse() {
        pulseResetWork?.cancel()
        pulse = true
        let work = DispatchWorkItem { pulse = false }
        pulseResetWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: work)
    }

    private func triggerPRFlash() {
        prFlashResetWork?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            prFlashActive = true
        }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.4)) { prFlashActive = false }
        }
        prFlashResetWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
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
