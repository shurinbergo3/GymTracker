//
//  AchievementsHubCard.swift
//  GymTracker
//
//  Bright, motivating hub used when the user has no Apple Watch /
//  Activity Rings data. Shows level, XP progress, weekly goal,
//  total workouts and next milestone — so progress feels rewarding
//  even without ring data. Tappable: opens AchievementsDetailView.
//

import SwiftUI

// MARK: - Milestones

private struct AchievementMilestone {
    let workouts: Int
    let title: String
    let icon: String
    let tint: Color
}

private let milestones: [AchievementMilestone] = [
    .init(workouts: 1,   title: "Первая",      icon: "flag.fill",            tint: .green),
    .init(workouts: 5,   title: "Бронза",      icon: "medal.fill",           tint: Color(red: 0.85, green: 0.55, blue: 0.30)),
    .init(workouts: 15,  title: "Серебро",     icon: "medal.fill",           tint: Color(white: 0.78)),
    .init(workouts: 30,  title: "Золото",      icon: "medal.fill",           tint: Color(red: 1.0, green: 0.82, blue: 0.20)),
    .init(workouts: 50,  title: "Платина",     icon: "rosette",              tint: Color(red: 0.5,  green: 0.85, blue: 1.0)),
    .init(workouts: 100, title: "Легенда",     icon: "crown.fill",           tint: Color(red: 1.0,  green: 0.4,  blue: 0.85))
]

// MARK: - Card

struct AchievementsHubCard: View {
    let totalWorkouts: Int
    let workoutsThisWeek: Int
    let weeklyGoal: Int
    /// Set of normalized days (startOfDay) on which the user trained — used for streak.
    var trainedDays: Set<Date> = []
    /// Most-recent workout date — drives form-state and XP-decay visualisation.
    var lastWorkoutDate: Date? = nil

    private var peakLevel: Int { GamificationCalculator.peakLevel(totalWorkouts: totalWorkouts) }
    private var level: Int { GamificationCalculator.currentLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff) }
    private var hasLostLevel: Bool { peakLevel > level }
    private var rawXPInLevel: Int { GamificationCalculator.rawXPInLevel(totalWorkouts: totalWorkouts) }
    private var daysOff: Int? { GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate) }
    private var formState: FormState { GamificationCalculator.formState(daysSinceLastWorkout: daysOff) }
    private var effectiveXPInLevel: Double {
        GamificationCalculator.effectiveXPInLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var xpProgress: Double {
        GamificationCalculator.xpProgress(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var visibleDecay: Double {
        GamificationCalculator.visibleDecay(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var hasDecayWarning: Bool { visibleDecay > 0 }

    private var nextMilestone: AchievementMilestone? {
        milestones.first { $0.workouts > totalWorkouts }
    }

    /// Current streak counted from today/yesterday backwards.
    private var currentStreak: Int {
        let cal = Calendar.current
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

    /// True when the user trained yesterday but not today and the streak is at risk.
    private var streakInDanger: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard !trainedDays.contains(today) else { return false }
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return false }
        return trainedDays.contains(yesterday)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            xpBar
            milestonesRow
            footerRow
            tapHint
        }
        .padding(DesignSystem.Spacing.lg)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.45),
                            DesignSystem.Colors.accentPurple.opacity(0.35),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.18), radius: 18, x: 0, y: 8)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            // Avatar (uses the actual user photo / initials when signed in)
            AvatarView(size: 50)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Уровень \(level)".localized().localizedUppercase)
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.4)
                        .foregroundStyle(hasLostLevel ? formState.color : Color(red: 1.0, green: 0.7, blue: 0.2))

                    if hasLostLevel {
                        peakBadge
                    }
                }

                Text(GamificationCalculator.athleteTitle(for: level))
                    .font(DesignSystem.Typography.title2())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalWorkouts)")
                    .font(DesignSystem.Typography.monospaced(.title2, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("тренировок".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Peak badge

    private var peakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 8, weight: .heavy))
            Text("БЫЛ \(peakLevel)".localized())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.8)
        }
        .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.40))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.16))
        )
        .overlay(
            Capsule().stroke(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.45), lineWidth: 0.5)
        )
    }

    // MARK: - XP bar
    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("XP до следующего уровня".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)

                if hasDecayWarning {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 9, weight: .heavy))
                        Text(decayLabel)
                            .font(DesignSystem.Typography.monospaced(.caption2, weight: .bold))
                    }
                    .foregroundStyle(formState.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(formState.color.opacity(0.16)))
                }

                Spacer()
                Text(xpCounterLabel)
                    .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.2))
            }

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let earnedFraction = Double(rawXPInLevel) / 5.0
                let effectiveFraction = xpProgress
                let earnedWidth = max(0, totalWidth * earnedFraction)
                let effectiveWidth = max(0, totalWidth * effectiveFraction)

                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10)

                    // Ghost only meaningful when decay is within the same level.
                    if hasDecayWarning && !hasLostLevel {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        formState.color.opacity(0.35),
                                        formState.color.opacity(0.10)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, earnedWidth), height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(formState.color.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            )
                    }

                    // Effective (kept) XP
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2),
                                    Color(red: 1.0, green: 0.4, blue: 0.55),
                                    DesignSystem.Colors.accentPurple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(effectiveFraction > 0 ? 8 : 0, effectiveWidth), height: 10)
                        .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.5), radius: 6, x: 0, y: 2)
                }
            }
            .frame(height: 10)
        }
    }

    /// "1.4/5" when decay reduced XP, otherwise "2/5".
    private var xpCounterLabel: String {
        if hasDecayWarning {
            let formatted = String(format: "%.1f", effectiveXPInLevel)
            return "\(formatted)/\(GamificationCalculator.xpPerLevel)"
        }
        return "\(rawXPInLevel)/\(GamificationCalculator.xpPerLevel)"
    }

    private var decayLabel: String {
        let v = visibleDecay
        return v >= 0.95 ? "−\(Int(v.rounded()))" : "−\(String(format: "%.1f", v))"
    }

    // MARK: - Milestones row
    private var milestonesRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                let unlocked = milestone.workouts <= totalWorkouts
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(unlocked ? milestone.tint.opacity(0.18) : Color.white.opacity(0.04))
                            .frame(width: 38, height: 38)
                        Image(systemName: unlocked ? milestone.icon : "lock.fill")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(unlocked ? milestone.tint : DesignSystem.Colors.tertiaryText)
                    }
                    .overlay(
                        Circle().stroke(
                            unlocked ? milestone.tint.opacity(0.35) : Color.clear,
                            lineWidth: 1
                        )
                    )

                    Text("\(milestone.workouts)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(unlocked ? milestone.tint : DesignSystem.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Footer
    private var footerRow: some View {
        HStack(spacing: 10) {
            // Weekly goal
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("\(min(workoutsThisWeek, weeklyGoal))/\(weeklyGoal)")
                    .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("за неделю".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DesignSystem.Colors.neonGreen.opacity(0.10))
            .overlay(Capsule().stroke(DesignSystem.Colors.neonGreen.opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())

            Spacer()

            // Next milestone hint
            if let next = nextMilestone {
                let remaining = next.workouts - totalWorkouts
                HStack(spacing: 6) {
                    Image(systemName: next.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(next.tint)
                    Text("\("ещё".localized()) \(remaining) → \(next.title.localized())")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
            } else {
                Text("Все награды собраны 🏆".localized())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.20))
            }
        }
    }

    // MARK: - Tap hint / motivation message

    @ViewBuilder
    private var tapHint: some View {
        let message = motivationalMessage()
        HStack(spacing: 8) {
            Image(systemName: message.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(message.tint)
            Text(message.text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(2)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(message.tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(message.tint.opacity(0.20), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers
    private struct MotivationMessage {
        let text: String
        let icon: String
        let tint: Color
    }

    private func motivationalMessage() -> MotivationMessage {
        // Level loss is the loudest signal — surface it first
        if hasLostLevel {
            return MotivationMessage(
                text: "Уровень упал до \(level) — верни \(peakLevel)".localized(),
                icon: "arrow.down.heart.fill",
                tint: formState.color
            )
        }
        if formState == .declining {
            return MotivationMessage(
                text: "Теряешь форму — уровень под угрозой".localized(),
                icon: formState.icon,
                tint: formState.color
            )
        }
        if formState == .warning {
            return MotivationMessage(
                text: "Форма снижается — пора в зал".localized(),
                icon: formState.icon,
                tint: formState.color
            )
        }
        if streakInDanger {
            return MotivationMessage(
                text: "Серия в опасности — тренируйся сегодня".localized(),
                icon: "exclamationmark.triangle.fill",
                tint: .orange
            )
        }
        if currentStreak >= 3 {
            return MotivationMessage(
                text: "\(currentStreak) дней подряд! Не останавливайся.".localized(),
                icon: "flame.fill",
                tint: .red
            )
        }
        if workoutsThisWeek >= weeklyGoal {
            return MotivationMessage(
                text: "Недельная цель выполнена 🔥".localized(),
                icon: "checkmark.seal.fill",
                tint: DesignSystem.Colors.neonGreen
            )
        }
        if totalWorkouts == 0 {
            return MotivationMessage(
                text: "Начни первую тренировку — XP начнут расти".localized(),
                icon: "sparkles",
                tint: Color(red: 1.0, green: 0.7, blue: 0.2)
            )
        }
        return MotivationMessage(
            text: "Подробнее: статистика, награды, серия".localized(),
            icon: "chart.bar.fill",
            tint: DesignSystem.Colors.accentPurple
        )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.10, blue: 0.10),
                    Color(red: 0.07, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 220
            )
        }
    }
}

// MARK: - Smart wrapper that picks card based on Activity Rings availability

struct ActivityHeroSection: View {
    let totalWorkouts: Int
    let workoutsThisWeek: Int
    var weeklyGoal: Int = 4
    /// Pass workout history so the card can compute streaks / motivation.
    var history: [WorkoutSession] = []
    /// Tap handler — opens detailed achievements view when the card is tapped.
    var onTap: (() -> Void)? = nil

    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled = true
    @State private var hasActivityRingsData: Bool? = nil  // nil = not yet checked

    private var trainedDays: Set<Date> {
        Set(history.map { Calendar.current.startOfDay(for: $0.date) })
    }

    private var lastWorkoutDate: Date? {
        history.map { $0.date }.max()
    }

    var body: some View {
        Group {
            // Show rings only if user explicitly enabled Apple Watch and HealthKit has data.
            if isAppleWatchEnabled, hasActivityRingsData == true {
                ActivityRingsCard()
            } else {
                hubCard
            }
        }
        .task {
            await detectActivityRings()
        }
        .onChange(of: isAppleWatchEnabled) { _, _ in
            Task { await detectActivityRings(force: true) }
        }
    }

    private var hubCard: some View {
        Button {
            onTap?()
        } label: {
            AchievementsHubCard(
                totalWorkouts: totalWorkouts,
                workoutsThisWeek: workoutsThisWeek,
                weeklyGoal: weeklyGoal,
                trainedDays: trainedDays,
                lastWorkoutDate: lastWorkoutDate
            )
        }
        .buttonStyle(.plain)
    }

    private func detectActivityRings(force: Bool = false) async {
        if !force, hasActivityRingsData != nil { return }

        guard isAppleWatchEnabled else {
            await MainActor.run { self.hasActivityRingsData = false }
            return
        }

        if !HealthManager.shared.isAuthorized {
            await MainActor.run { self.hasActivityRingsData = false }
            return
        }

        let summary = await HealthManager.shared.fetchActivitySummary()
        let hasData: Bool = {
            guard let s = summary else { return false }
            let move = s.activeEnergyBurned.doubleValue(for: .kilocalorie())
            let stand = s.appleStandHours.doubleValue(for: .count())
            let exercise = s.appleExerciseTime.doubleValue(for: .minute())
            return move > 1 || stand > 0 || exercise > 0
        }()

        await MainActor.run {
            self.hasActivityRingsData = hasData
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            AchievementsHubCard(totalWorkouts: 12, workoutsThisWeek: 2, weeklyGoal: 4)
            AchievementsHubCard(totalWorkouts: 47, workoutsThisWeek: 5, weeklyGoal: 4)
        }
        .padding()
    }
    .environmentObject(AuthManager.shared)
}
