//
//  ExpandableCalendarView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ExpandableCalendarView: View {
    @Query private var allSessions: [WorkoutSession]
    @State private var isExpanded: Bool
    @State private var selectedMonth = Date()
    @State private var selectedSession: WorkoutSession?

    /// When true, the calendar is permanently expanded: chevron hidden, tap-to-collapse disabled.
    /// Use this when the calendar is presented in a dedicated sheet where the week-strip mode
    /// would leave most of the screen empty.
    private let lockedExpanded: Bool

    /// Days that have an Apple Health workout but NO Body Forge session.
    /// Rendered with a different marker so the user can see external
    /// activity (walks, cycling, etc.) at a glance.
    private let externalWorkoutDays: Set<Date>

    init(initiallyExpanded: Bool = false,
         lockedExpanded: Bool = false,
         externalWorkoutDays: Set<Date> = []) {
        self._isExpanded = State(initialValue: initiallyExpanded || lockedExpanded)
        self.lockedExpanded = lockedExpanded
        self.externalWorkoutDays = externalWorkoutDays
    }

    var body: some View {
        CardView {
            VStack(spacing: DesignSystem.Spacing.md) {
                MonthHeaderView(
                    month: selectedMonth,
                    isExpanded: isExpanded,
                    showsToggleChevron: !lockedExpanded,
                    onPreviousMonth: previousMonth,
                    onNextMonth: nextMonth,
                    onToggleExpand: {
                        guard !lockedExpanded else { return }
                        withAnimation { isExpanded.toggle() }
                    }
                )

                if isExpanded {
                    FullMonthView(
                        month: selectedMonth,
                        completedDates: completedDates,
                        externalDates: externalOnlyDates,
                        onDaySelected: handleDaySelection
                    )
                } else {
                    WeekView(
                        date: Date(),
                        completedDates: completedDates,
                        externalDates: externalOnlyDates,
                        onDaySelected: handleDaySelection
                    )
                }
            }
            .padding(DesignSystem.Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !lockedExpanded else { return }
                withAnimation { isExpanded.toggle() }
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutHistoryDetailView(session: session)
        }
    }

    // Cache normalized dates for O(1) lookup
    private var completedDates: Set<Date> {
        let calendar = Calendar.current
        return Set(allSessions.compactMap { session -> Date? in
            guard session.isCompleted else { return nil }
            return calendar.startOfDay(for: session.date)
        })
    }

    /// Days with an external (Apple Health) workout that don't already
    /// contain a Body Forge session — avoids overlapping markers.
    private var externalOnlyDates: Set<Date> {
        externalWorkoutDays.subtracting(completedDates)
    }

    private func handleDaySelection(_ date: Date) {
        // Find session for this date
        if let session = allSessions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.isCompleted }) {
            selectedSession = session
        }
    }

    private func previousMonth() {
        withAnimation {
            if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                selectedMonth = newDate
            }
        }
    }

    private func nextMonth() {
        withAnimation {
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                selectedMonth = newDate
            }
        }
    }
}

// MARK: - Month Header

struct MonthHeaderView: View {
    let month: Date
    let isExpanded: Bool
    var showsToggleChevron: Bool = true
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToggleExpand: () -> Void
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month).capitalized
    }
    
    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.accent)
            }
            
            // Tappable Middle Section
            HStack(spacing: 4) {
                Spacer()
                Text(monthYearText)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(DesignSystem.Colors.primaryText)

                if showsToggleChevron {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggleExpand() }
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.accent)
            }
        }
    }
}

// MARK: - Week View

struct WeekView: View {
    let date: Date
    let completedDates: Set<Date>
    var externalDates: Set<Date> = []
    let onDaySelected: (Date) -> Void

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7

        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: weekStart)
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(weekDates, id: \.self) { date in
                Button(action: { onDaySelected(date) }) {
                    DayCell(
                        date: date,
                        isToday: Calendar.current.isDateInToday(date),
                        hasWorkout: completedDates.contains(Calendar.current.startOfDay(for: date)),
                        hasExternal: externalDates.contains(Calendar.current.startOfDay(for: date))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Full Month View

struct FullMonthView: View {
    let month: Date
    let completedDates: Set<Date>
    var externalDates: Set<Date> = []
    let onDaySelected: (Date) -> Void

    private var monthDates: [[Date?]] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromMonday = (firstWeekday + 5) % 7

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = Array(repeating: nil, count: daysFromMonday)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                currentWeek.append(date)

                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // День недели заголовки
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(["М", "Т", "С", "Ч", "П", "С", "В"].enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // Недели
            ForEach(Array(monthDates.enumerated()), id: \.offset) { _, week in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        if let date = date {
                            Button(action: { onDaySelected(date) }) {
                                DayCell(
                                    date: date,
                                    isToday: Calendar.current.isDateInToday(date),
                                    hasWorkout: completedDates.contains(Calendar.current.startOfDay(for: date)),
                                    hasExternal: externalDates.contains(Calendar.current.startOfDay(for: date))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasWorkout: Bool
    var hasExternal: Bool = false

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(DesignSystem.Typography.callout())
                .fontWeight(isToday ? .heavy : .semibold)
                .foregroundColor(isToday ? .black : DesignSystem.Colors.primaryText)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isToday {
                            // Неоновый светящийся круг
                            Circle()
                                .fill(DesignSystem.Colors.neonGreen)
                                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 8, x: 0, y: 0)
                        } else if hasWorkout {
                            Circle()
                                .stroke(DesignSystem.Colors.accent.opacity(0.5), lineWidth: 2)
                        } else if hasExternal {
                            // Apple Health-only: розовое кольцо помягче.
                            Circle()
                                .stroke(Color.pink.opacity(0.55), lineWidth: 2)
                        }
                    }
                )
                .cornerRadius(18)

            // Иконка тренировки или отдыха
            if hasWorkout {
                // Иконка гантели для дня с тренировкой Body Forge
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
            } else if hasExternal {
                // Иконка сердца для дня только с Apple Health активностью
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.pink)
            } else {
                // Иконка релакса для дня отдыха
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ExpandableCalendarView()
        .modelContainer(for: [WorkoutSession.self], inMemory: true)
        .padding()
}
