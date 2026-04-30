//
//  WeeklyStreakStrip.swift
//  GymTracker
//
//  Bright compact strip that shows the current weekly training streak.
//  7 day pills (Mon..Sun, locale-aware), neon for completed days,
//  highlighted ring for today.
//

import SwiftUI

struct WeeklyStreakStrip: View {
    let sessions: [WorkoutSession]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.currentLocale
        cal.firstWeekday = 2 // Monday
        return cal
    }

    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        // Find Monday of the current week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7 // 0 if Monday, 6 if Sunday
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private var trainedDays: Set<Date> {
        let cal = calendar
        let days = sessions.map { cal.startOfDay(for: $0.date) }
        return Set(days)
    }

    private var completedThisWeek: Int {
        weekDays.filter { trainedDays.contains($0) }.count
    }

    private var streak: Int {
        // Count consecutive days from yesterday backwards (or today if trained today)
        let cal = calendar
        var current = cal.startOfDay(for: Date())
        var count = 0
        // If today not trained, start from yesterday
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
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    dayPill(day)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.neonGreen.opacity(0.18), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.12), radius: 14, x: 0, y: 6)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, DesignSystem.Colors.neonGreen],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(DesignSystem.Typography.monospaced(.title2, weight: .heavy))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text(streakSuffix(streak))
                        .font(DesignSystem.Typography.callout())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
                Text("Серия".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.2)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(completedThisWeek)/7")
                    .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                Text("на этой неделе".localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Day pill

    private func dayPill(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isTrained = trainedDays.contains(day)
        let isFuture = day > calendar.startOfDay(for: Date())

        return VStack(spacing: 6) {
            Text(weekdayLetter(day))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isToday ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)

            ZStack {
                Circle()
                    .fill(pillFill(isTrained: isTrained, isToday: isToday, isFuture: isFuture))
                    .frame(width: 30, height: 30)

                if isTrained {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.black)
                } else if isToday {
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 6, height: 6)
                }
            }
            .overlay(
                Circle()
                    .stroke(
                        isToday ? DesignSystem.Colors.neonGreen : Color.clear,
                        lineWidth: 1.5
                    )
                    .frame(width: 36, height: 36)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func pillFill(isTrained: Bool, isToday: Bool, isFuture: Bool) -> AnyShapeStyle {
        if isTrained {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [DesignSystem.Colors.neonGreen, Color(red: 0.6, green: 0.9, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else if isFuture {
            return AnyShapeStyle(Color.white.opacity(0.04))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
    }

    // MARK: - Helpers

    private func weekdayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "EE"
        let raw = formatter.string(from: date)
        return String(raw.prefix(2)).uppercased()
    }

    private func streakSuffix(_ value: Int) -> String {
        // Russian-friendly plural
        let mod10 = value % 10
        let mod100 = value % 100
        if mod10 == 1 && mod100 != 11 {
            return "день подряд".localized()
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "дня подряд".localized()
        } else {
            return "дней подряд".localized()
        }
    }

    private var background: some View {
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
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WeeklyStreakStrip(sessions: [])
            .padding()
    }
}
