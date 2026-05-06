//
//  AppleHealthActivityCard.swift
//  GymTracker
//
//  Dashboard card surfacing workouts the user did outside Body Forge
//  (Apple Watch fitness, Strava, Nike Run Club, etc.) so the gym app
//  reflects their full activity picture, not only logged sessions.
//

import SwiftUI
import HealthKit

struct AppleHealthActivityCard: View {
    let workouts: [ExternalWorkout]
    var onTap: () -> Void = {}

    private var totalMinutes: Int {
        workouts.reduce(0) { $0 + $1.durationMinutes }
    }

    private var totalCalories: Int {
        Int(workouts.reduce(0.0) { $0 + ($1.totalEnergyBurnedKcal ?? 0) })
    }

    private var uniqueDays: Int {
        let cal = Calendar.current
        return Set(workouts.map { cal.startOfDay(for: $0.startDate) }).count
    }

    /// Up to 4 most recent activities — enough for a glanceable strip.
    private var preview: [ExternalWorkout] {
        Array(workouts.prefix(4))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                header
                if workouts.isEmpty {
                    emptyState
                } else {
                    statsRow
                    Divider().background(Color.white.opacity(0.06))
                    activityStrip
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(borderGradient, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .shadow(color: Color.pink.opacity(0.10), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.pink)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("Активность за 7 дней".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            Spacer()
            if !workouts.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("Нет тренировок из Apple Health за неделю".localized())
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Stats row
    private var statsRow: some View {
        HStack(spacing: 8) {
            statChip(
                icon: "list.bullet",
                value: "\(workouts.count)",
                label: "тренировок".localized(),
                tint: Color.pink
            )
            statChip(
                icon: "clock.fill",
                value: minutesLabel,
                label: "общее".localized(),
                tint: Color(red: 0.45, green: 0.85, blue: 1.0)
            )
            statChip(
                icon: "flame.fill",
                value: "\(totalCalories)",
                label: "ккал".localized(),
                tint: .orange
            )
            statChip(
                icon: "calendar",
                value: "\(uniqueDays)",
                label: "дней".localized(),
                tint: DesignSystem.Colors.accentPurple
            )
        }
    }

    private var minutesLabel: String {
        if totalMinutes >= 60 {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            if m == 0 { return String(format: "%dч".localized(), h) }
            return String(format: "%dч%dм".localized(), h, m)
        }
        return String(format: "%dм".localized(), totalMinutes)
    }

    private func statChip(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint)
                Text(label.uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            Text(value)
                .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(tint.opacity(0.20), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Activity strip
    private var activityStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(preview) { w in
                ExternalWorkoutRow(workout: w, dense: true)
            }
            if workouts.count > preview.count {
                Text(String(format: "ещё +%d".localized(), workouts.count - preview.count))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Background
    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.08), Color(white: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.pink.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [Color(red: 0.45, green: 0.85, blue: 1.0).opacity(0.08), .clear],
                center: .bottomLeading,
                startRadius: 4,
                endRadius: 220
            )
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [Color.pink.opacity(0.30), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Reusable row used in dashboard, history & detail sheet

struct ExternalWorkoutRow: View {
    let workout: ExternalWorkout
    var dense: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(workout.tint.opacity(0.18))
                    .frame(width: dense ? 32 : 40, height: dense ? 32 : 40)
                Image(systemName: workout.iconName)
                    .font(.system(size: dense ? 14 : 18, weight: .semibold))
                    .foregroundStyle(workout.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.displayName)
                    .font(dense ? .subheadline.weight(.semibold) : .headline)
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(workout.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    if let cals = workout.totalEnergyBurnedKcal, cals > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("\(Int(cals))")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.orange)
                    }
                    if let dist = workout.formattedDistance {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                        Text(dist)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 1.0))
                    }
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(relativeDateLabel(workout.startDate))
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                Text(workout.sourceName)
                    .font(.caption2)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }

    private func relativeDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "сегодня".localized() }
        if cal.isDateInYesterday(date) { return "вчера".localized() }
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: - Detail sheet — full list of external workouts

struct AppleHealthWorkoutsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let workouts: [ExternalWorkout]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(workouts) { w in
                            ExternalWorkoutRow(workout: w, dense: false)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(w.tint.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(Text("Apple Health"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }
}
