//
//  AchievementsDetailView.swift
//  GymTracker
//
//  Full-screen achievements & stats breakdown opened from
//  the Achievements Hub card on the dashboard.
//

import SwiftUI
import PhotosUI

// MARK: - Detailed milestone

struct AchievementBadge: Identifiable {
    let id = UUID()
    let workouts: Int
    let title: String
    let icon: String
    let tint: Color
    let blurb: String
}

private let badges: [AchievementBadge] = [
    .init(workouts: 1,   title: "Первая",   icon: "flag.fill",   tint: .green,
          blurb: "Самый сложный шаг — начало. Ты его сделал."),
    .init(workouts: 5,   title: "Бронза",   icon: "medal.fill",   tint: Color(red: 0.85, green: 0.55, blue: 0.30),
          blurb: "Привычка формируется. 21 день — порог автоматизма."),
    .init(workouts: 15,  title: "Серебро",  icon: "medal.fill",   tint: Color(white: 0.78),
          blurb: "Тело уже отвечает на нагрузку — нейромышечные связи окрепли."),
    .init(workouts: 30,  title: "Золото",   icon: "medal.fill",   tint: Color(red: 1.0, green: 0.82, blue: 0.20),
          blurb: "Месяц регулярной работы. Видны первые силовые сдвиги."),
    .init(workouts: 50,  title: "Платина",  icon: "rosette",      tint: Color(red: 0.5, green: 0.85, blue: 1.0),
          blurb: "Атлетический уровень. Гипертрофия и сила работают вместе."),
    .init(workouts: 100, title: "Легенда",  icon: "crown.fill",   tint: Color(red: 1.0, green: 0.4, blue: 0.85),
          blurb: "Сотня тренировок — твоё тело и характер другие.")
]

// MARK: - View

struct AchievementsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let totalWorkouts: Int
    let history: [WorkoutSession]
    let workoutsThisWeek: Int

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }

    // MARK: - Derived stats

    private var lastWorkoutDate: Date? { history.map { $0.date }.max() }
    private var daysOff: Int? { GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate) }
    private var level: Int { GamificationCalculator.currentLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff) }
    private var peakLevel: Int { GamificationCalculator.peakLevel(totalWorkouts: totalWorkouts) }
    private var hasLostLevel: Bool { peakLevel > level }
    private var rawXPInLevel: Int { GamificationCalculator.rawXPInLevel(totalWorkouts: totalWorkouts) }
    private var formState: FormState { GamificationCalculator.formState(daysSinceLastWorkout: daysOff) }
    private var effectiveXPInLevel: Double {
        GamificationCalculator.effectiveXPInLevel(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var visibleDecay: Double {
        GamificationCalculator.visibleDecay(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var xpProgress: Double {
        GamificationCalculator.xpProgress(totalWorkouts: totalWorkouts, daysSinceLastWorkout: daysOff)
    }
    private var hasDecayWarning: Bool { visibleDecay > 0 }
    private var nextBadge: AchievementBadge? { badges.first { $0.workouts > totalWorkouts } }

    /// Total tonnage lifted across the cached history (kg).
    private var totalTonnage: Double {
        history.reduce(0) { $0 + $1.volume }
    }

    /// Best streak ever (consecutive days with completed workouts).
    private var bestStreak: Int {
        guard !history.isEmpty else { return 0 }
        let trainedDays = Set(history.map { calendar.startOfDay(for: $0.date) })
        guard !trainedDays.isEmpty else { return 0 }
        let sorted = trainedDays.sorted()
        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: sorted[i-1]),
               calendar.isDate(prev, inSameDayAs: sorted[i]) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    /// Current streak counted from today/yesterday backwards.
    private var currentStreak: Int {
        let trainedDays = Set(history.map { calendar.startOfDay(for: $0.date) })
        var current = calendar.startOfDay(for: Date())
        var count = 0
        if !trainedDays.contains(current) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: current) else { return 0 }
            current = y
        }
        while trainedDays.contains(current) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return count
    }

    /// Average workouts per week over the last 4 calendar weeks.
    private var avgPerWeek: Double {
        let now = Date()
        guard let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now) else { return 0 }
        let recent = history.filter { $0.date >= fourWeeksAgo }
        return Double(recent.count) / 4.0
    }

    /// Total active time (sum of session durations) in minutes.
    private var totalMinutes: Int {
        let total = history.reduce(0.0) { acc, s in
            guard let end = s.endTime else { return acc }
            return acc + max(0, end.timeIntervalSince(s.date))
        }
        return Int(total / 60)
    }

    /// Most-trained muscle group (from exercise names mapped to library).
    private var topMuscleGroup: String? {
        var counts: [String: Int] = [:]
        for session in history {
            for set in session.sets {
                if let ex = ExerciseLibrary.getExercise(for: set.exerciseName) {
                    counts[ex.muscleGroup.rawValue, default: 0] += 1
                }
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var weeklyGoal: Int { 4 }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        heroHeader
                        formExplainerCard
                        howItWorksCard
                        statsGrid
                        streakCard
                        badgesSection
                        nextStepCallout

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("Прогресс и награды".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                AvatarView(size: 64, isEditable: true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(String(format: "Уровень %d".localized(), level).localizedUppercase)
                            .font(DesignSystem.Typography.sectionHeader())
                            .tracking(1.4)
                            .foregroundStyle(hasLostLevel ? formState.color : Color(red: 1.0, green: 0.7, blue: 0.2))

                        if hasLostLevel {
                            HStack(spacing: 3) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 9, weight: .heavy))
                                Text(String(format: "ПИК %d".localized(), peakLevel))
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .tracking(0.8)
                            }
                            .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.40))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.16)))
                            .overlay(Capsule().stroke(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.45), lineWidth: 0.5))
                        }
                    }

                    Text(GamificationCalculator.athleteTitle(for: level))
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(.white)
                }

                Spacer()
            }

            // XP bar with decay viz
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("XP до следующего уровня".localized())
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    if hasDecayWarning {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 9, weight: .heavy))
                            Text(decayChipLabel)
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
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                }

                GeometryReader { geo in
                    let earnedW = max(0, geo.size.width * Double(rawXPInLevel) / 5.0)
                    let effW = max(0, geo.size.width * xpProgress)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08)).frame(height: 12)

                        // Ghost only meaningful when XP decayed within the SAME level.
                        // If level itself dropped, ghost belongs to a different level — hide it.
                        if hasDecayWarning && !hasLostLevel {
                            Capsule()
                                .fill(formState.color.opacity(0.30))
                                .frame(width: earnedW, height: 12)
                                .overlay(
                                    Capsule().stroke(formState.color.opacity(0.4),
                                                     style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                )
                        }

                        Capsule()
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
                            .frame(width: max(xpProgress > 0 ? 10 : 0, effW), height: 12)
                            .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.5), radius: 6)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.13, green: 0.10, blue: 0.10), Color(red: 0.07, green: 0.05, blue: 0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.18), .clear],
                    center: .topLeading,
                    startRadius: 4,
                    endRadius: 220
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
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
    }

    // MARK: - How it works

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                Text("Как это работает".localized())
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                HowItWorksRow(icon: "bolt.fill", color: Color(red: 1.0, green: 0.7, blue: 0.2),
                              text: "+1 XP за каждую завершённую тренировку".localized())
                HowItWorksRow(icon: "arrow.up.circle.fill", color: DesignSystem.Colors.accentPurple,
                              text: "Каждые 5 XP = новый уровень".localized())
                HowItWorksRow(icon: "flame.fill", color: .orange,
                              text: "Серия — сколько дней подряд ты тренируешься".localized())
                HowItWorksRow(icon: "medal.fill", color: Color(red: 1.0, green: 0.82, blue: 0.20),
                              text: "Бэйджи открываются за общее число тренировок".localized())
                HowItWorksRow(icon: "arrow.down.heart.fill", color: Color(red: 1.0, green: 0.27, blue: 0.30),
                              text: "Без тренировок дольше 3 дней XP начинает падать. После 14 дней можно потерять и уровень — но «пик» останется как трофей.".localized())
                HowItWorksRow(icon: "trophy.fill", color: Color(red: 0.85, green: 0.70, blue: 0.40),
                              text: "Бэйдж «ПИК» хранит твой максимальный уровень — его можно вернуть, продолжив тренировки.".localized())
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatTile(icon: "dumbbell.fill", label: "Всего тренировок".localized(),
                     value: "\(totalWorkouts)", tint: DesignSystem.Colors.neonGreen)
            StatTile(icon: "scalemass.fill", label: "Суммарный тоннаж".localized(),
                     value: formatTonnage(totalTonnage), tint: .orange)
            StatTile(icon: "flame.fill", label: "Лучшая серия".localized(),
                     value: "\(bestStreak)", subtitle: bestStreakSuffix, tint: .red)
            StatTile(icon: "calendar", label: "Среднее за неделю".localized(),
                     value: String(format: "%.1f", avgPerWeek), tint: .blue)
            StatTile(icon: "stopwatch.fill", label: "Время в зале".localized(),
                     value: formatMinutes(totalMinutes), tint: .yellow)
            StatTile(icon: "scope", label: "Любимая группа".localized(),
                     value: topMuscleGroup ?? "—", isCompact: true, tint: .pink)
        }
    }

    // MARK: - Streak card

    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.orange.opacity(0.5), radius: 14)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak) \(streakSuffix(currentStreak))")
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(.white)
                Text(streakHint)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var streakHint: String {
        if currentStreak == 0 {
            return "Тренируйся сегодня, чтобы начать новую серию".localized()
        } else if currentStreak < bestStreak {
            return String(format: "Лучший рекорд: %1$d. До него — %2$d".localized(), bestStreak, bestStreak - currentStreak)
        } else {
            return "Это твой новый рекорд. Не упусти его!".localized()
        }
    }

    // MARK: - Badges grid

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rosette")
                    .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.20))
                Text("Награды".localized())
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(.white)
                Spacer()
                Text("\(badges.filter { $0.workouts <= totalWorkouts }.count)/\(badges.count)")
                    .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }

            VStack(spacing: 10) {
                ForEach(badges) { badge in
                    BadgeRow(badge: badge, totalWorkouts: totalWorkouts)
                }
            }
        }
    }

    // MARK: - Next step callout

    @ViewBuilder
    private var nextStepCallout: some View {
        if let next = nextBadge {
            let remaining = next.workouts - totalWorkouts
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(next.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Следующая цель".localized())
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(String(format: "%@ — ещё %d тренировок".localized(), next.title, remaining))
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [next.tint.opacity(0.20), DesignSystem.Colors.cardBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(next.tint.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - Form / decay helpers + explainer card

    private var xpCounterLabel: String {
        if hasDecayWarning {
            return "\(String(format: "%.1f", effectiveXPInLevel))/\(GamificationCalculator.xpPerLevel)"
        }
        return "\(rawXPInLevel)/\(GamificationCalculator.xpPerLevel)"
    }

    private var decayChipLabel: String {
        visibleDecay >= 0.95 ? "−\(Int(visibleDecay.rounded()))" : "−\(String(format: "%.1f", visibleDecay))"
    }

    private var decayInfoText: String {
        let lost = decayChipLabel.replacingOccurrences(of: "−", with: "")
        if hasLostLevel {
            let drop = peakLevel - level
            let lvlWord = drop == 1 ? "уровень" : "уровня"
            return String(format: "Упал на %1$d %2$@ и %3$@ XP. Тренировка восстановит прогресс — и доведёт обратно к Уровню %4$d.".localized(), drop, lvlWord, lost, peakLevel)
        }
        return String(format: "Потеряно %@ XP — одна тренировка восстановит форму".localized(), lost)
    }

    private var daysOffLabel: String {
        guard let d = daysOff else { return "—" }
        switch d {
        case 0:     return "сегодня".localized()
        case 1:     return "вчера".localized()
        case 2...4: return "\(d) " + "дня назад".localized()
        default:    return "\(d) " + "дней назад".localized()
        }
    }

    @ViewBuilder
    private var formExplainerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(formState.color.opacity(0.20))
                        .frame(width: 38, height: 38)
                    Image(systemName: formState.icon)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(formState.color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("ФОРМА".localized() + " · " + formState.title.localizedUppercase)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(formState.color)
                    Text(formState.subtitle)
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(daysOffLabel)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("последняя".localized().uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
            }

            // Decay timeline — visualises 4 phases
            HStack(spacing: 4) {
                decayPhase(label: "0-2 дн", state: .peak)
                decayPhase(label: "3-7 дн", state: .stable)
                decayPhase(label: "8-14 дн", state: .warning)
                decayPhase(label: "15+ дн", state: .declining)
            }

            if hasDecayWarning {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(formState.color)
                    Text(decayInfoText)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                DesignSystem.Colors.cardBackground
                LinearGradient(
                    colors: [formState.color.opacity(0.15), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(formState.color.opacity(0.30), lineWidth: 1)
        )
    }

    private func decayPhase(label: String, state: FormState) -> some View {
        let isCurrent = state == formState
        return VStack(spacing: 4) {
            Capsule()
                .fill(isCurrent ? state.color : Color.white.opacity(0.06))
                .frame(height: 4)
                .shadow(color: isCurrent ? state.color.opacity(0.5) : .clear, radius: 4)
            Text(label)
                .font(.system(size: 9, weight: isCurrent ? .heavy : .semibold, design: .rounded))
                .foregroundStyle(isCurrent ? state.color : DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stat helpers

    private func formatTonnage(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1f т", kg / 1000)
        } else if kg > 0 {
            return "\(Int(kg)) кг"
        }
        return "—"
    }

    private func formatMinutes(_ min: Int) -> String {
        if min >= 60 {
            return "\(min / 60) ч \(min % 60) м"
        }
        return "\(min) м"
    }

    private var bestStreakSuffix: String? {
        guard bestStreak > 0 else { return nil }
        return streakSuffix(bestStreak)
    }

    private func streakSuffix(_ value: Int) -> String {
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

// MARK: - Subviews

private struct HowItWorksRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            Spacer()
        }
    }
}

private struct StatTile: View {
    let icon: String
    let label: String
    let value: String
    var subtitle: String? = nil
    var isCompact: Bool = false
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                }
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(isCompact ? DesignSystem.Typography.headline() : DesignSystem.Typography.title2())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct BadgeRow: View {
    let badge: AchievementBadge
    let totalWorkouts: Int

    private var unlocked: Bool { totalWorkouts >= badge.workouts }
    private var progress: Double { min(1.0, Double(totalWorkouts) / Double(badge.workouts)) }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(unlocked ? badge.tint.opacity(0.20) : Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                Image(systemName: unlocked ? badge.icon : "lock.fill")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(unlocked ? badge.tint : DesignSystem.Colors.tertiaryText)
            }
            .overlay(
                Circle().stroke(unlocked ? badge.tint.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(badge.title.localized())
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(unlocked ? .white : DesignSystem.Colors.secondaryText)
                    Spacer()
                    Text("\(min(totalWorkouts, badge.workouts))/\(badge.workouts)")
                        .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                        .foregroundColor(unlocked ? badge.tint : DesignSystem.Colors.tertiaryText)
                }

                Text(badge.blurb.localized())
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .lineLimit(2)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        Capsule()
                            .fill(badge.tint)
                            .frame(width: max(4, geo.size.width * progress), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(unlocked ? badge.tint.opacity(0.20) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Avatar

struct AvatarView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var avatarStore = AvatarStore.shared
    let size: CGFloat
    /// When true, tapping the avatar opens a photo picker so the user can
    /// upload their own image. A small camera badge is shown in the corner.
    var isEditable: Bool = false

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingActionSheet = false

    private var uid: String? { authManager.currentUser?.uid }

    private var localAvatarURL: URL? {
        // Read `avatarStore.version` so SwiftUI re-evaluates when the file changes.
        _ = avatarStore.version
        return avatarStore.currentFileURL(uid: uid)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarCircle

            if isEditable {
                editBadge
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onTapGesture {
            guard isEditable else { return }
            if localAvatarURL != nil {
                showingActionSheet = true
            } else {
                // Trigger picker by re-binding to a fresh state — see hidden picker below.
                isPickerPresented = true
            }
        }
        .photosPicker(
            isPresented: $isPickerPresented,
            selection: $pickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadAndSave(item: newItem) }
        }
        .confirmationDialog("Фото профиля".localized(), isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Изменить фото".localized()) { isPickerPresented = true }
            Button("Удалить фото".localized(), role: .destructive) {
                avatarStore.clear(uid: uid)
            }
            Button("Отмена".localized(), role: .cancel) { }
        }
    }

    @State private var isPickerPresented = false

    // MARK: - Subviews

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.2),
                            Color(red: 1.0, green: 0.4, blue: 0.55),
                            DesignSystem.Colors.accentPurple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.5), radius: size / 5)

            content
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var editBadge: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.neonGreen)
                .frame(width: size * 0.32, height: size * 0.32)
                .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            Image(systemName: "camera.fill")
                .font(.system(size: size * 0.16, weight: .heavy))
                .foregroundColor(.black)
        }
        .overlay(
            Circle().stroke(DesignSystem.Colors.background, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var content: some View {
        if let local = localAvatarURL, let img = UIImage(contentsOfFile: local.path) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
        } else if authManager.isLoggedIn, let user = authManager.currentUser {
            if let url = user.photoURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView(user.avatarInitials)
                }
                .frame(width: size, height: size)
            } else {
                initialsView(user.avatarInitials)
            }
        } else {
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundColor(.black)
        }
    }

    private func initialsView(_ initials: String) -> some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(width: size, height: size)
    }

    // MARK: - Picker handling

    private func loadAndSave(item: PhotosPickerItem) async {
        defer { Task { @MainActor in self.pickerItem = nil } }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                _ = avatarStore.save(data, for: uid)
            }
        } catch {
            #if DEBUG
            print("⚠️ AvatarView: failed to load picked photo — \(error)")
            #endif
        }
    }
}

#Preview {
    AchievementsDetailView(
        totalWorkouts: 12,
        history: [],
        workoutsThisWeek: 2
    )
    .environmentObject(AuthManager.shared)
}
