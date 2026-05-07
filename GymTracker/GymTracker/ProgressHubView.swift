//
//  ProgressHubView.swift
//  GymTracker
//
//  Unified progress hub: hero (level/XP/form) + segmented tabs
//  (Обзор / Рекорды / Награды / Аналитика). Single-tap from the
//  dashboard — no nested sheets.
//

import SwiftUI
import SwiftData
import Charts

struct ProgressHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var selectedTab: ProgressTab = .overview
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @Namespace private var tabIndicator

    // MARK: - Tabs

    enum ProgressTab: String, CaseIterable, Identifiable {
        case overview, records, awards, analytics
        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview:  return "Обзор".localized()
            case .records:   return "Рекорды".localized()
            case .awards:    return "Награды".localized()
            case .analytics: return "Аналитика".localized()
            }
        }

        var icon: String {
            switch self {
            case .overview:  return "square.grid.2x2.fill"
            case .records:   return "trophy.fill"
            case .awards:    return "rosette"
            case .analytics: return "chart.line.uptrend.xyaxis"
            }
        }

        var tint: Color {
            switch self {
            case .overview:  return DesignSystem.Colors.neonGreen
            case .records:   return Color(red: 1.0, green: 0.82, blue: 0.20)
            case .awards:    return Color(red: 1.0, green: 0.55, blue: 0.20)
            case .analytics: return DesignSystem.Colors.accentPurple
            }
        }
    }

    enum AnalyticsPeriod: String, CaseIterable {
        case week, month, quarter, year

        var title: String {
            switch self {
            case .week:    return "Неделя".localized()
            case .month:   return "Месяц".localized()
            case .quarter: return "3 мес.".localized()
            case .year:    return "Год".localized()
            }
        }

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }

    // MARK: - Calendar

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }

    // MARK: - Derived data

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }

    private var totalCompleted: Int { completedSessions.count }

    private var trainedDays: Set<Date> {
        Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
    }

    private var workoutsThisWeek: Int {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return completedSessions.filter { $0.date >= monday }.count
    }

    private var weeklyGoal: Int { 4 }

    private var recentPRs: [PersonalRecord] {
        PersonalRecordsService.recentPRs(from: completedSessions, limit: 10)
    }

    private var nextTarget: PRTarget? {
        PersonalRecordsService.nextTarget(from: completedSessions)
    }

    private var currentStreak: Int {
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

    private var bestStreak: Int {
        guard !trainedDays.isEmpty else { return 0 }
        let sorted = trainedDays.sorted()
        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: sorted[i-1]),
               calendar.isDate(prev, inSameDayAs: sorted[i]) {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }

    private var streakInDanger: Bool {
        let today = calendar.startOfDay(for: Date())
        guard !trainedDays.contains(today) else { return false }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return false }
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

    private var avgPerWeek: Double {
        guard let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: Date()) else { return 0 }
        let recent = completedSessions.filter { $0.date >= fourWeeksAgo }
        return Double(recent.count) / 4.0
    }

    private var topMuscleGroup: String? {
        var counts: [String: Int] = [:]
        for session in completedSessions {
            for set in session.sets {
                if let ex = ExerciseLibrary.getExercise(for: set.exerciseName) {
                    counts[ex.muscleGroup.rawValue, default: 0] += 1
                }
            }
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var unlockedBadges: Int {
        achievementBadges.filter { $0.workouts <= totalCompleted }.count
    }

    private var totalBadges: Int { achievementBadges.count }

    private var nextBadge: AchievementBadge? {
        achievementBadges.first { $0.workouts > totalCompleted }
    }

    private var daysOff: Int? {
        GamificationCalculator.daysSinceLastWorkout(from: lastWorkoutDate)
    }

    private var level: Int {
        GamificationCalculator.currentLevel(totalWorkouts: totalCompleted, daysSinceLastWorkout: daysOff)
    }

    private var peakLevel: Int {
        GamificationCalculator.peakLevel(totalWorkouts: totalCompleted)
    }

    private var hasLostLevel: Bool { peakLevel > level }

    private var rawXPInLevel: Int {
        GamificationCalculator.rawXPInLevel(totalWorkouts: totalCompleted)
    }

    private var effectiveXPInLevel: Double {
        GamificationCalculator.effectiveXPInLevel(totalWorkouts: totalCompleted, daysSinceLastWorkout: daysOff)
    }

    private var visibleDecay: Double {
        GamificationCalculator.visibleDecay(totalWorkouts: totalCompleted, daysSinceLastWorkout: daysOff)
    }

    private var xpProgress: Double {
        GamificationCalculator.xpProgress(totalWorkouts: totalCompleted, daysSinceLastWorkout: daysOff)
    }

    private var hasDecay: Bool { visibleDecay > 0 }

    private var formState: FormState {
        GamificationCalculator.formState(daysSinceLastWorkout: daysOff)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    quickStatsRow
                    tabBar
                    tabContent
                        .id(selectedTab)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Прогресс".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }

    // MARK: - HERO

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                AvatarView(size: 64, isEditable: true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(String(format: "Уровень %d".localized(), level).localizedUppercase)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .tracking(1.6)
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
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(totalCompleted)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text("ТРЕНИРОВОК".localized())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
            }

            xpStrip
            formStrip
        }
        .padding(18)
        .background(heroBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(heroBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: formState.color.opacity(0.18), radius: 22, x: 0, y: 10)
    }

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

    private var formStrip: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(formState.color.opacity(0.20))
                    .frame(width: 30, height: 30)
                Image(systemName: formState.icon)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(formState.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\("ФОРМА".localized()) · \(formState.title.localizedUppercase)")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(1.2)
                    .foregroundStyle(formState.color)
                Text(formState.subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(daysOffLabel)
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(formState.color.opacity(0.28), lineWidth: 1)
        )
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.13),
                    Color(red: 0.05, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [formState.color.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 280
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 260
            )
        }
    }

    private var heroBorder: LinearGradient {
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

    // MARK: - Quick stats row

    private var quickStatsRow: some View {
        HStack(spacing: 8) {
            quickStatTile(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: streakSuffix(currentStreak).uppercased(),
                tint: currentStreak > 0 ? .orange : DesignSystem.Colors.tertiaryText
            )
            quickStatTile(
                icon: "scalemass.fill",
                value: tonnageDisplay,
                label: "ТОННАЖ".localized(),
                tint: Color(red: 1.0, green: 0.7, blue: 0.2)
            )
            quickStatTile(
                icon: "stopwatch.fill",
                value: minutesDisplay,
                label: "ВРЕМЯ".localized(),
                tint: .yellow
            )
            quickStatTile(
                icon: "rosette",
                value: "\(unlockedBadges)/\(totalBadges)",
                label: "БЭЙДЖИ".localized(),
                tint: Color(red: 1.0, green: 0.82, blue: 0.20)
            )
        }
    }

    private func quickStatTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 0.8)
        )
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(ProgressTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .heavy))
                        Text(tab.title)
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundStyle(selectedTab == tab ? .black : .white.opacity(0.6))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(tab.tint)
                                    .matchedGeometryEffect(id: "tabBG", in: tabIndicator)
                                    .shadow(color: tab.tint.opacity(0.45), radius: 8, x: 0, y: 4)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Tab content router

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:  overviewTab
        case .records:   recordsTab
        case .awards:    awardsTab
        case .analytics: analyticsTab
        }
    }

    // MARK: - TAB: Обзор

    private var overviewTab: some View {
        VStack(spacing: 14) {
            decayTimelineCard
            streakDetailCard
            weeklyGoalCard
            if let next = nextBadge {
                nextBadgeRow(next)
            }
            howItWorksCard
        }
    }

    private var decayTimelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(formState.color)
                Text("Состояние формы".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: 4) {
                decayPhase(label: "0–2 дн".localized(), state: .peak)
                decayPhase(label: "3–7 дн".localized(), state: .stable)
                decayPhase(label: "8–14 дн".localized(), state: .warning)
                decayPhase(label: "15+ дн".localized(), state: .declining)
            }

            if hasDecay {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(formState.color)
                    Text(decayInfoText)
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Свежая мышечная адаптация — лучшее окно для нового PR.".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(formState.color.opacity(0.22), lineWidth: 1)
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

    private var streakDetailCard: some View {
        let danger = streakInDanger
        let tint: Color = danger ? .red : (currentStreak > 0 ? .orange : DesignSystem.Colors.tertiaryText)
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: tint.opacity(0.5), radius: 10)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(currentStreak) \(streakSuffix(currentStreak))")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                    if bestStreak > currentStreak {
                        Text(String(format: "лучшая %d".localized(), bestStreak))
                            .font(.caption2.bold())
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.05)))
                    }
                }
                Text(streakHint)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.30), lineWidth: 1)
        )
    }

    private var weeklyGoalCard: some View {
        let progress = min(1.0, Double(workoutsThisWeek) / Double(weeklyGoal))
        let done = workoutsThisWeek >= weeklyGoal
        let tint: Color = done ? DesignSystem.Colors.neonGreen : Color(red: 1.0, green: 0.7, blue: 0.2)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: done ? "checkmark.seal.fill" : "target")
                    .foregroundStyle(tint)
                Text("Цель недели".localized())
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(workoutsThisWeek)/\(weeklyGoal)")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                        .shadow(color: tint.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 8)

            Text(done
                 ? "Цель закрыта — респект.".localized()
                 : String(format: "Ещё %d до цели".localized(), max(0, weeklyGoal - workoutsThisWeek)))
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }

    private func nextBadgeRow(_ next: AchievementBadge) -> some View {
        let remaining = next.workouts - totalCompleted
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedTab = .awards
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(next.tint.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: next.icon)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(next.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Следующая награда".localized())
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    Text(String(format: "%@ — ещё %d".localized(), next.title.localized(), remaining))
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [next.tint.opacity(0.18), DesignSystem.Colors.cardBackground],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(next.tint.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("Как это работает".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                HowItWorksRow(icon: "bolt.fill", color: Color(red: 1.0, green: 0.7, blue: 0.2),
                              text: "+1 XP за каждую завершённую тренировку".localized())
                HowItWorksRow(icon: "arrow.up.circle.fill", color: DesignSystem.Colors.accentPurple,
                              text: "Каждые 5 XP = новый уровень".localized())
                HowItWorksRow(icon: "flame.fill", color: .orange,
                              text: "Серия — сколько дней подряд ты тренируешься".localized())
                HowItWorksRow(icon: "rosette", color: Color(red: 1.0, green: 0.82, blue: 0.20),
                              text: "Бэйджи открываются за общее число тренировок".localized())
                HowItWorksRow(icon: "arrow.down.heart.fill", color: Color(red: 1.0, green: 0.27, blue: 0.30),
                              text: "Без тренировок дольше 3 дней XP падает. После 14 дней можно потерять и уровень — но «пик» останется как трофей.".localized())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - TAB: Рекорды

    private var recordsTab: some View {
        VStack(spacing: 14) {
            if let target = nextTarget {
                prTargetCard(target)
            }

            if recentPRs.isEmpty {
                emptyState(
                    icon: "trophy",
                    title: "Пока нет рекордов".localized(),
                    subtitle: "Заверши тренировку — мы автоматически найдём новые PR.".localized()
                )
            } else {
                prsListCard
            }
        }
    }

    private func prTargetCard(_ target: PRTarget) -> some View {
        let accent = DesignSystem.Colors.accent
        let weight = formatWeight(target.baseWeight)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundStyle(accent)
                Text("Следующий рекорд".localized())
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            Text(LocalizedStringKey(target.exerciseName))
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)

            HStack(spacing: 10) {
                pillStat(label: "Сейчас".localized(), value: "\(weight) × \(target.baseReps)", tint: .white.opacity(0.7))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(accent)
                pillStat(label: "Цель".localized(), value: "\(weight) × \(target.targetReps)", tint: accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.15), DesignSystem.Colors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.30), lineWidth: 1)
        )
    }

    private func pillStat(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var prsListCard: some View {
        let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(gold)
                Text("Личные рекорды".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(recentPRs.count)")
                    .font(.caption.bold())
                    .foregroundStyle(gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(gold.opacity(0.18)))
            }

            VStack(spacing: 8) {
                ForEach(recentPRs) { pr in
                    prRow(pr)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(gold.opacity(0.20), lineWidth: 1)
        )
    }

    private func prRow(_ pr: PersonalRecord) -> some View {
        let gold = Color(red: 1.0, green: 0.82, blue: 0.20)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .heavy))
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
            prBadge(for: pr)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func prBadge(for pr: PersonalRecord) -> some View {
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

    // MARK: - TAB: Награды

    private var awardsTab: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rosette")
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.20))
                Text("Награды".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(unlockedBadges)/\(totalBadges)")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            // Badges grid (2 columns) — denser, more visual
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(achievementBadges) { badge in
                    BadgeCardCompact(badge: badge, totalWorkouts: totalCompleted)
                }
            }

            if let next = nextBadge {
                nextBadgeRow(next)
            }
        }
    }

    // MARK: - TAB: Аналитика

    private var analyticsTab: some View {
        VStack(spacing: 14) {
            periodSelector
            trendCard
            exerciseBreakdownCard
            volumeChartCard
            extraStatsRow
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 6) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = period }
                } label: {
                    Text(period.title)
                        .font(.system(.caption, design: .rounded, weight: selectedPeriod == period ? .heavy : .semibold))
                        .foregroundStyle(selectedPeriod == period ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedPeriod == period ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filteredSessions: [WorkoutSession] {
        let cutoff = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return completedSessions.filter { $0.date >= cutoff }
    }

    private var breakdown: ProgressTrend.Breakdown {
        ProgressTrend.analyze(from: completedSessions)
    }

    private var progressTrend: ProgressTrend { breakdown.trend }

    private var trendCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [progressTrend.color.opacity(0.30), progressTrend.color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Image(systemName: progressTrend.icon)
                    .font(.system(size: 46, weight: .heavy))
                    .foregroundStyle(progressTrend.color)
                    .rotationEffect(.degrees(progressTrend.rotation))
            }
            .shadow(color: progressTrend.color.opacity(0.30), radius: 14)

            VStack(spacing: 4) {
                Text(progressTrend.title)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Text(progressTrend.subtitle)
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(progressTrend.color.opacity(0.20), lineWidth: 1)
        )
    }

    private var exerciseBreakdownCard: some View {
        let bd = breakdown
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("Прогресс по упражнениям".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
                if !bd.isInsufficientData && bd.totalTracked > 0 {
                    Text("\(bd.growing)/\(bd.totalTracked)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }

            if bd.isInsufficientData {
                Text("Соберём данные ещё за пару тренировок — и покажем прогресс по каждому упражнению.".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                HStack(spacing: 8) {
                    summaryChip(count: bd.growing, label: "растут".localized(), color: DesignSystem.Colors.neonGreen)
                    summaryChip(count: bd.stable, label: "стабильно".localized(), color: Color.white.opacity(0.5))
                    summaryChip(count: bd.declining, label: "снижение".localized(), color: .orange)
                }

                VStack(spacing: 6) {
                    ForEach(bd.exercises) { progress in
                        exerciseRow(progress)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.15), lineWidth: 1)
        )
    }

    private func summaryChip(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func exerciseRow(_ p: ProgressTrend.ExerciseProgress) -> some View {
        HStack(spacing: 12) {
            Image(systemName: p.direction.icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(p.direction.color)
                .frame(width: 24, height: 24)
                .background(p.direction.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(p.exerciseName))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(formatScore(p.priorBest)) → \(formatScore(p.recentBest)) \(p.unit.localizedSuffix)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            Spacer()
            Text(formatPercent(p.percentChange))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(p.direction.color)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var volumeChartCard: some View {
        let chartData: [(date: Date, volume: Double)] = filteredSessions.reversed().map { s in
            (date: s.date, volume: s.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) })
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("Объём тренировок".localized())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }

            if chartData.isEmpty {
                Text("Недостаточно данных за этот период".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Chart {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                        AreaMark(
                            x: .value("Тренировка".localized(), index),
                            y: .value("Объём".localized(), data.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [progressTrend.color.opacity(0.5), progressTrend.color.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Тренировка".localized(), index),
                            y: .value("Объём".localized(), data.volume)
                        )
                        .foregroundStyle(progressTrend.color)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .frame(height: 130)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(progressTrend.color.opacity(0.18), lineWidth: 1)
        )
    }

    private var extraStatsRow: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            extraStat(icon: "calendar", label: "Среднее за неделю".localized(),
                      value: String(format: "%.1f", avgPerWeek), tint: .blue)
            extraStat(icon: "flame.fill", label: "Лучшая серия".localized(),
                      value: "\(bestStreak)", tint: .red)
            extraStat(icon: "scope", label: "Любимая группа".localized(),
                      value: topMuscleGroup ?? "—", tint: .pink, compact: true)
            extraStat(icon: "calendar.badge.clock", label: "За период".localized(),
                      value: "\(filteredSessions.count)", tint: DesignSystem.Colors.accentPurple)
        }
    }

    private func extraStat(icon: String, label: String, value: String, tint: Color, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(tint)
                }
                Spacer()
            }
            Text(value)
                .font(compact
                      ? .system(.subheadline, design: .rounded, weight: .heavy)
                      : .system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Empty state

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Helpers

    private var xpCounter: String {
        if hasDecay {
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
            let lvlWord = drop == 1 ? "уровень".localized() : "уровня".localized()
            return String(format: "Упал на %1$d %2$@ и %3$@ XP. Тренировка восстановит прогресс — и доведёт обратно к Уровню %4$d.".localized(), drop, lvlWord, lost, peakLevel)
        }
        return String(format: "Потеряно %@ XP — одна тренировка восстановит форму".localized(), lost)
    }

    private var daysOffLabel: String {
        guard let d = daysOff else { return "—" }
        switch d {
        case 0:        return "сегодня".localized()
        case 1:        return "вчера".localized()
        case 2...4:    return "\(d) " + "дня назад".localized()
        default:       return "\(d) " + "дней назад".localized()
        }
    }

    private var streakHint: String {
        if streakInDanger {
            return "Потренируйся сегодня — иначе серия сбросится".localized()
        }
        if currentStreak == 0 {
            return "Начни новую серию сегодня".localized()
        }
        if currentStreak < bestStreak {
            return String(format: "До рекорда — %d".localized(), bestStreak - currentStreak)
        }
        return "Это твой новый рекорд. Не упусти!".localized()
    }

    private var tonnageDisplay: String {
        if totalTonnage >= 1000 {
            return String(format: "%.1f т", totalTonnage / 1000)
        }
        return totalTonnage > 0 ? "\(Int(totalTonnage)) кг" : "—"
    }

    private var minutesDisplay: String {
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)ч \(totalMinutes % 60)м"
        }
        return "\(totalMinutes) м"
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
            return "\(days) \(streakSuffix(days)) \(String(localized: "назад"))"
        }
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    private func formatScore(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        if value.truncatingRemainder(dividingBy: 1) == 0 { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }

    private func formatPercent(_ pct: Double) -> String {
        let sign = pct > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))%"
    }
}

// MARK: - BadgeCardCompact (visual badge tile, 2-column grid)

struct BadgeCardCompact: View {
    let badge: AchievementBadge
    let totalWorkouts: Int

    private var unlocked: Bool { totalWorkouts >= badge.workouts }
    private var progress: Double { min(1.0, Double(totalWorkouts) / Double(badge.workouts)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                        ? LinearGradient(
                            colors: [badge.tint.opacity(0.30), badge.tint.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle().stroke(unlocked ? badge.tint.opacity(0.45) : Color.white.opacity(0.05), lineWidth: 1.5)
                    )
                    .shadow(color: unlocked ? badge.tint.opacity(0.35) : .clear, radius: 10)
                Image(systemName: unlocked ? badge.icon : "lock.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(unlocked ? badge.tint : DesignSystem.Colors.tertiaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title.localized())
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(unlocked ? .white : DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
                Text(badge.blurb.localized())
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.07)).frame(height: 4)
                        Capsule()
                            .fill(unlocked ? badge.tint : Color.white.opacity(0.25))
                            .frame(width: max(4, geo.size.width * progress), height: 4)
                    }
                }
                .frame(height: 4)

                Text("\(min(totalWorkouts, badge.workouts))/\(badge.workouts)")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(unlocked ? badge.tint : DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(unlocked ? badge.tint.opacity(0.30) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    ProgressHubView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
        .environmentObject(AuthManager.shared)
}
