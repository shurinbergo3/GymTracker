//
//  HistoryHeroCard.swift
//  GymTracker
//
//  Bento-style hero card for the workout history entry point.
//  Shows total workouts, last workout date, a 14-day mini bar chart
//  of session volume, and quick aggregate stats (hours, sets, records).
//

import SwiftUI
import Charts

struct HistoryHeroCard: View {
    let sessions: [WorkoutSession]
    let totalCompletedCount: Int

    // MARK: - Derived

    private var lastSession: WorkoutSession? {
        sessions.first
    }

    private var lastDateLabel: String {
        guard let date = lastSession?.date else { return "—" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        switch days {
        case 0:    return "сегодня".localized()
        case 1:    return "вчера".localized()
        case 2..<7: return "\(days) " + dayPlural(days) + " " + "назад".localized()
        default:
            let f = DateFormatter()
            f.locale = LanguageManager.shared.currentLocale
            f.dateFormat = "d MMM"
            return f.string(from: date)
        }
    }

    /// Total time across the 100-session window (good enough for a hero glance).
    private var totalHoursLabel: String {
        let secs = sessions.reduce(0.0) { acc, s in
            acc + (s.endTime?.timeIntervalSince(s.date) ?? 0)
        }
        let hours = Int(secs / 3600)
        let mins = Int((secs.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours == 0 { return "\(mins)м".localized() }
        return "\(hours)ч".localized() + (mins > 0 ? " \(mins)м".localized() : "")
    }

    private var totalSets: Int {
        sessions.reduce(0) { $0 + $1.sets.count }
    }

    private var lastWorkoutCalories: Int {
        lastSession?.calories ?? 0
    }

    /// 14 day buckets (oldest first) of session counts. Used by the mini chart.
    private var dailyBuckets: [DailyHealthValue] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -13, to: today) else { return [] }

        var counts: [Date: Int] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            if day >= start && day <= today {
                counts[day, default: 0] += 1
            }
        }

        return (0...13).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyHealthValue(date: day, value: Double(counts[day] ?? 0))
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            heroRow
            if !sessions.isEmpty {
                miniChart
            }
            statsFooter
        }
        .padding(DesignSystem.Spacing.lg)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(neonStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.15), radius: 18, x: 0, y: 8)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("История тренировок".localized())
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text("Все ваши прошлые сессии".localized())
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
    }

    // MARK: - Hero Row (Big number + Last)
    private var heroRow: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(totalCompletedCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primaryText, DesignSystem.Colors.neonGreen.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(workoutPlural(totalCompletedCount).uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.4)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Spacer()

            // Last workout pill
            VStack(alignment: .trailing, spacing: 6) {
                Text("ПОСЛЕДНЯЯ".localized())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)

                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 5, height: 5)
                    Text(lastDateLabel)
                        .font(DesignSystem.Typography.monospaced(.subheadline, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }

                if lastWorkoutCalories > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(lastWorkoutCalories) ккал".localized())
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Mini Chart
    private var miniChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("14 ДНЕЙ".localized())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                Spacer()
                Text("\(workoutsLast14)")
                    .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                + Text(" / 14")
                    .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Chart {
                ForEach(dailyBuckets) { bucket in
                    BarMark(
                        x: .value("d", bucket.date, unit: .day),
                        y: .value("v", max(bucket.value, 0.05))
                    )
                    .foregroundStyle(
                        bucket.value > 0
                        ? AnyShapeStyle(DesignSystem.Colors.neonGreen.gradient)
                        : AnyShapeStyle(Color.white.opacity(0.06))
                    )
                    .cornerRadius(3)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 38)
        }
    }

    private var workoutsLast14: Int {
        Int(dailyBuckets.reduce(0) { $0 + $1.value })
    }

    // MARK: - Stats Footer
    private var statsFooter: some View {
        HStack(spacing: 8) {
            statChip(icon: "clock.fill", value: totalHoursLabel, label: "общее время".localized(), tint: Color(red: 0.45, green: 0.85, blue: 1.0))
            statChip(icon: "list.number", value: "\(totalSets)", label: "подходов".localized(), tint: DesignSystem.Colors.neonGreen)
            statChip(icon: "calendar", value: "\(uniqueDaysCount)", label: "дней".localized(), tint: DesignSystem.Colors.accentPurple)
        }
    }

    private var uniqueDaysCount: Int {
        let cal = Calendar.current
        return Set(sessions.map { cal.startOfDay(for: $0.date) }).count
    }

    @ViewBuilder
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

    // MARK: - Background
    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(white: 0.08),
                    Color(white: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.08), .clear],
                center: .bottomLeading,
                startRadius: 4,
                endRadius: 220
            )
        }
    }

    private var neonStroke: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.neonGreen.opacity(0.30),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Plurals (RU-friendly)
    private func workoutPlural(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "тренировка".localized() }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "тренировки".localized() }
        return "тренировок".localized()
    }

    private func dayPlural(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день".localized() }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня".localized() }
        return "дней".localized()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HistoryHeroCard(sessions: [], totalCompletedCount: 47)
            .padding()
    }
}
