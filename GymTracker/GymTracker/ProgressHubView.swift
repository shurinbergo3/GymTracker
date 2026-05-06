//
//  ProgressHubView.swift
//  GymTracker
//
//  Unified progress hub: trend, streak, next PR target, recent PRs, level/XP, deep analytics.
//

import SwiftUI
import SwiftData

struct ProgressHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var showingAnalytics = false
    @State private var showingAllMilestones = false

    // MARK: - Derived data

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }

    private var totalCompleted: Int { completedSessions.count }

    private var trainedDays: Set<Date> {
        Set(completedSessions.map { Calendar.current.startOfDay(for: $0.date) })
    }

    private var workoutsThisWeek: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return completedSessions.filter { $0.date >= monday }.count
    }

    private var weeklyGoal: Int { 4 }

    private var recentPRs: [PersonalRecord] {
        PersonalRecordsService.recentPRs(from: completedSessions, limit: 5)
    }

    private var nextTarget: PRTarget? {
        PersonalRecordsService.nextTarget(from: completedSessions)
    }

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

    private var streakInDanger: Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard !trainedDays.contains(today) else { return false }
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return false }
        return trainedDays.contains(yesterday)
    }

    private var lastWorkoutDate: Date? { completedSessions.first?.date }

    private var totalTonnage: Double {
        completedSessions.reduce(0) { $0 + $1.volume }
    }

    private var totalMinutes: Int {
        let total = completedSessions.reduce(0.0) { acc, s in
            guard let end = s.endTime else { return acc }
            return acc + max(0, end.timeIntervalSince(s.date))
        }
        return Int(total / 60)
    }

    private var unlockedBadges: Int {
        let thresholds = [1, 5, 15, 30, 50, 100]
        return thresholds.filter { $0 <= totalCompleted }.count
    }

    private var totalBadges: Int { 6 }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    gamificationHero
                    actionableSection
                    prsFeed
                    analyticsButton
                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Прогресс".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
            .sheet(isPresented: $showingAnalytics) {
                ProgressDetailView()
            }
            .sheet(isPresented: $showingAllMilestones) {
                AchievementsDetailView(
                    totalWorkouts: totalCompleted,
                    history: completedSessions,
                    workoutsThisWeek: workoutsThisWeek
                )
            }
        }
    }

    // MARK: - Athlete Profile Card (gateway to full stats)

    private var gamificationHero: some View {
        AthleteProfileCard(
            totalWorkouts: totalCompleted,
            level: GamificationCalculator.currentLevel(
                totalWorkouts: totalCompleted,
                daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
            ),
            peakLevel: GamificationCalculator.peakLevel(totalWorkouts: totalCompleted),
            rawXPInLevel: GamificationCalculator.rawXPInLevel(totalWorkouts: totalCompleted),
            xpProgress: GamificationCalculator.xpProgress(
                totalWorkouts: totalCompleted,
                daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
            ),
            effectiveXPInLevel: GamificationCalculator.effectiveXPInLevel(
                totalWorkouts: totalCompleted,
                daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
            ),
            visibleDecay: GamificationCalculator.visibleDecay(
                totalWorkouts: totalCompleted,
                daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
            ),
            formState: GamificationCalculator.formState(
                daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
            ),
            daysSinceLastWorkout: GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate),
            currentStreak: currentStreak,
            totalTonnageKg: totalTonnage,
            totalMinutes: totalMinutes,
            unlockedBadges: unlockedBadges,
            totalBadges: totalBadges,
            onOpen: { showingAllMilestones = true }
        )
    }

    // MARK: - Actionable rows: streak + next PR target

    @ViewBuilder
    private var actionableSection: some View {
        VStack(spacing: 10) {
            if currentStreak > 0 || streakInDanger {
                streakRow
            }
            if let target = nextTarget {
                prTargetRow(target)
            }
        }
    }

    private var streakRow: some View {
        let isDanger = streakInDanger
        let tint: Color = isDanger ? .red : .orange
        let title: String
        if isDanger {
            title = String(localized: "Серия под угрозой")
        } else {
            title = "\(String(localized: "Серия")) \(currentStreak) \(dayPlural(currentStreak))"
        }
        let subtitle: String = isDanger
            ? String(localized: "Потренируйся сегодня, иначе серия сбросится")
            : String(localized: "Так держать! Не пропускай дни.")

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private func prTargetRow(_ target: PRTarget) -> some View {
        let accent = DesignSystem.Colors.accent
        let weight = formatWeight(target.baseWeight)
        let detail = "\(String(localized: "Попробуй")) \(weight)×\(target.targetReps) (\(String(localized: "рекорд")) \(weight)×\(target.baseReps))"
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(localized: "Цель:")) \(target.exerciseName)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - PRs feed

    @ViewBuilder
    private var prsFeed: some View {
        if !recentPRs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.20))
                    Text("Личные рекорды".localized())
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(recentPRs.count)")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.20))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(red: 1.0, green: 0.82, blue: 0.20).opacity(0.18)))
                }

                VStack(spacing: 8) {
                    ForEach(recentPRs) { pr in
                        prRow(pr)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 1.0, green: 0.82, blue: 0.20).opacity(0.20), lineWidth: 1)
            )
        }
    }

    private func prRow(_ pr: PersonalRecord) -> some View {
        let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(pr.exerciseName))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(formatWeight(pr.weight)) × \(pr.reps) • \(formatPRDate(pr.date))")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            badge(for: pr)
        }
    }

    @ViewBuilder
    private func badge(for pr: PersonalRecord) -> some View {
        if pr.isFirstAtReps {
            Text("Новый".localized())
                .font(.caption2.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.16)))
        } else {
            Text("+\(formatWeight(pr.improvementKg))")
                .font(.caption2.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.16)))
        }
    }

    // MARK: - Analytics deep-link

    private var analyticsButton: some View {
        Button {
            showingAnalytics = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accent.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подробная аналитика".localized())
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Графики объёма, упражнения, периоды".localized())
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.accent.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatWeight(_ kg: Double) -> String {
        let unit = String(localized: "кг")
        if kg.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(kg)) \(unit)"
        }
        return "\(String(format: "%.1f", kg)) \(unit)"
    }

    private func formatPRDate(_ date: Date) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day],
                                       from: cal.startOfDay(for: date),
                                       to: cal.startOfDay(for: Date())).day ?? 0
        if days == 0 { return String(localized: "сегодня") }
        if days == 1 { return String(localized: "вчера") }
        if days < 7 {
            return "\(days) \(dayPlural(days)) \(String(localized: "назад"))"
        }
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    private func dayPlural(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return String(localized: "дней") }
        if mod10 == 1 { return String(localized: "день") }
        if mod10 >= 2 && mod10 <= 4 { return String(localized: "дня") }
        return String(localized: "дней")
    }
}

#Preview {
    ProgressHubView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}

// MARK: - Athlete Profile Card

/// Gateway preview card shown ONLY inside the Progress hub — visually distinct
/// from `AchievementsHubCard` (the entry-point on Stats/Workout tabs). Tease's
/// the rich content inside `AchievementsDetailView` so the user wants to dive in.
struct AthleteProfileCard: View {
    let totalWorkouts: Int
    let level: Int
    let peakLevel: Int
    let rawXPInLevel: Int
    let xpProgress: Double
    let effectiveXPInLevel: Double
    let visibleDecay: Double
    let formState: FormState
    let daysSinceLastWorkout: Int?
    let currentStreak: Int
    let totalTonnageKg: Double
    let totalMinutes: Int
    let unlockedBadges: Int
    let totalBadges: Int
    let onOpen: () -> Void

    @State private var formPulse: Bool = false
    @State private var pressed: Bool = false

    private var hasDecay: Bool { visibleDecay > 0 }

    private var formStatusLine: String {
        if let d = daysSinceLastWorkout {
            switch d {
            case 0:        return "сегодня".localized()
            case 1:        return "вчера".localized()
            case 2...4:    return "\(d) \("дня назад".localized())"
            default:       return "\(d) \("дней назад".localized())"
            }
        }
        return "ни одной тренировки".localized()
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(.easeOut(duration: 0.18)) { pressed = false }
                onOpen()
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                xpStrip
                formMeter
                statsTriplet
                ctaPill
            }
            .padding(18)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(borderGradient, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: formState.color.opacity(0.22), radius: 24, x: 0, y: 12)
            .scaleEffect(pressed ? 0.985 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                formPulse = true
            }
        }
    }

    // MARK: Header

    private var hasLostLevel: Bool { peakLevel > level }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 14) {
            AvatarView(size: 56)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(String(format: "Уровень %d".localized(), level).localizedUppercase)
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .tracking(1.6)
                        .foregroundStyle(hasLostLevel ? formState.color : Color(red: 1.0, green: 0.7, blue: 0.2))

                    if hasLostLevel {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 8, weight: .heavy))
                            Text(String(format: "БЫЛ %d".localized(), peakLevel))
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(0.8)
                        }
                        .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.40))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.16)))
                        .overlay(Capsule().stroke(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.45), lineWidth: 0.5))
                    }
                }

                Text(GamificationCalculator.athleteTitle(for: level))
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(totalWorkouts)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("ТРЕНИРОВОК".localized())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: XP strip

    private var xpStrip: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text("XP".localized())
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)

                if hasDecay {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 9, weight: .heavy))
                        Text(decayChipLabel)
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                    }
                    .foregroundStyle(formState.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(formState.color.opacity(0.16)))
                }

                Spacer()

                Text(xpCounter)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.2))
            }

            GeometryReader { geo in
                let earnedW = max(0, geo.size.width * Double(rawXPInLevel) / 5.0)
                let effW = max(0, geo.size.width * xpProgress)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.07))
                    if hasDecay && !hasLostLevel {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(formState.color.opacity(0.22))
                            .frame(width: earnedW)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(formState.color.opacity(0.35), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            )
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2),
                                    Color(red: 1.0, green: 0.4, blue: 0.55),
                                    DesignSystem.Colors.accentPurple
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(xpProgress > 0 ? 6 : 0, effW))
                        .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.5), radius: 5)
                }
            }
            .frame(height: 8)
        }
    }

    private var xpCounter: String {
        if hasDecay {
            return "\(String(format: "%.1f", effectiveXPInLevel))/\(GamificationCalculator.xpPerLevel)"
        }
        return "\(rawXPInLevel)/\(GamificationCalculator.xpPerLevel)"
    }

    private var decayChipLabel: String {
        visibleDecay >= 0.95 ? "−\(Int(visibleDecay.rounded()))" : "−\(String(format: "%.1f", visibleDecay))"
    }

    // MARK: Form meter — the killer detail

    private var formMeter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: formState.icon)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(formState.color)

                Text("ФОРМА".localized())
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.6)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)

                Text(verbatim: "·")
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)

                Text(formState.title.localizedUppercase)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(1.0)
                    .foregroundStyle(formState.color)
                    .opacity(formPulse ? 1.0 : 0.65)

                Spacer()

                Text(formStatusLine)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            // Vital-signs bar — scientific, ECG-like
            GeometryReader { geo in
                let w = geo.size.width * formState.fillFraction
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    formState.color.opacity(0.95),
                                    formState.color.opacity(0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, w))
                        .shadow(color: formState.color.opacity(0.55), radius: 8)

                    // Tick marks at decay thresholds (3d / 7d / 14d)
                    HStack(spacing: 0) {
                        Spacer().frame(width: geo.size.width * 0.40)
                        thresholdTick
                        Spacer().frame(width: geo.size.width * 0.32)
                        thresholdTick
                        Spacer().frame(width: geo.size.width * 0.15)
                        thresholdTick
                        Spacer()
                    }
                    .frame(height: 18)
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 18)

            Text(formState.subtitle)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(formState.color.opacity(0.28), lineWidth: 1)
        )
    }

    private var thresholdTick: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 18)
    }

    // MARK: Stats triplet

    private var statsTriplet: some View {
        HStack(spacing: 8) {
            statTile(
                icon: "scalemass.fill",
                value: tonnageDisplay,
                label: "ТОННАЖ".localized(),
                tint: .orange
            )
            statTile(
                icon: "stopwatch.fill",
                value: minutesDisplay,
                label: "ВРЕМЯ".localized(),
                tint: .yellow
            )
            statTile(
                icon: "rosette",
                value: "\(unlockedBadges)/\(totalBadges)",
                label: "БЭЙДЖИ".localized(),
                tint: Color(red: 1.0, green: 0.82, blue: 0.20)
            )
        }
    }

    private func statTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 0.8)
        )
    }

    private var tonnageDisplay: String {
        if totalTonnageKg >= 1000 {
            return String(format: "%.1f т", totalTonnageKg / 1000)
        }
        return totalTonnageKg > 0 ? "\(Int(totalTonnageKg)) кг" : "—"
    }

    private var minutesDisplay: String {
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)ч \(totalMinutes % 60)м"
        }
        return "\(totalMinutes) м"
    }

    // MARK: CTA pill

    private var ctaPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.accentPurple)

            VStack(alignment: .leading, spacing: 1) {
                Text("Открыть полный профиль".localized())
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Тоннаж · серии · бэйджи · детренинг".localized())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.accentPurple)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accentPurple.opacity(0.20),
                    DesignSystem.Colors.accentPurple.opacity(0.05)
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignSystem.Colors.accentPurple.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Background / border

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.13),
                    Color(red: 0.05, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Form-state colored radial — gives the card a "vital signs" hue
            RadialGradient(
                colors: [formState.color.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 280
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 260
            )
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                formState.color.opacity(0.55),
                Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.30),
                DesignSystem.Colors.accentPurple.opacity(0.45),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
