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

    private var trendBreakdown: ProgressTrend.Breakdown {
        ProgressTrend.analyze(from: completedSessions)
    }

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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    trendHero
                    actionableSection
                    prsFeed
                    levelCard
                    analyticsButton
                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .white.opacity(0.18))
                    }
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

    // MARK: - Trend hero (compact)

    private var trendHero: some View {
        let breakdown = trendBreakdown
        let trend = breakdown.trend
        let subtitle: String = breakdown.isInsufficientData
            ? String(localized: "Тренируйся регулярно — данные собираются")
            : trend.subtitle

        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [trend.color.opacity(0.40), trend.color.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: trend.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(trend.color)
                    .rotationEffect(.degrees(trend.rotation))
            }
            .shadow(color: trend.color.opacity(0.45), radius: 14, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(trend.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !breakdown.isInsufficientData && breakdown.totalTracked > 0 {
                    HStack(spacing: 6) {
                        miniChip("\(breakdown.growing)", String(localized: "растут"), .green)
                        miniChip("\(breakdown.stable)", String(localized: "стабильно"), .gray)
                        miniChip("\(breakdown.declining)", String(localized: "снижение"), .orange)
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(trend.color.opacity(0.30), lineWidth: 1)
        )
    }

    private func miniChip(_ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
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
                    Text("Личные рекорды")
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
            Text("Новый")
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

    // MARK: - Level/XP card

    private var levelCard: some View {
        // Compact milestones strip — replaces the duplicated AchievementsHubCard
        // that the user already tapped to open this screen. Tap = open the
        // full achievements detail with stats and badge progress.
        Button {
            showingAllMilestones = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2),
                                    Color(red: 1.0, green: 0.4, blue: 0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                    Image(systemName: "rosette")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Награды и статистика".localized())
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("\(unlockedBadgesCount)/\(totalBadgesCount) собрано • тоннаж, серии, PR".localized())
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
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
                    .stroke(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var milestoneThresholds: [Int] { [1, 5, 15, 30, 50, 100] }
    private var unlockedBadgesCount: Int { milestoneThresholds.filter { $0 <= totalCompleted }.count }
    private var totalBadgesCount: Int { milestoneThresholds.count }

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
                    Text("Подробная аналитика")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Графики объёма, упражнения, периоды")
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
