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
    @State private var isExpanded = false
    @State private var selectedMonth = Date()
    @State private var selectedSession: WorkoutSession?
    
    var body: some View {
        VStack(spacing: 0) { // Removed Button wrapper to allow inner buttons
            CardView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Заголовок с месяцем
                    MonthHeaderView(
                        month: selectedMonth,
                        isExpanded: isExpanded,
                        onPreviousMonth: previousMonth,
                        onNextMonth: nextMonth,
                        onToggleExpand: {
                            withAnimation { isExpanded.toggle() }
                        }
                    )
                    
                    if isExpanded {
                        // Полный месяц
                        FullMonthView(
                            month: selectedMonth,
                            sessions: allSessions,
                            onDaySelected: handleDaySelection
                        )
                    } else {
                        // Текущая неделя
                        WeekView(
                            date: Date(),
                            sessions: allSessions,
                            onDaySelected: handleDaySelection
                        )
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutHistoryDetailView(session: session)
        }
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
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onToggleExpand: () -> Void
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
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
            
            Spacer()
            
            Button(action: onToggleExpand) {
                HStack(spacing: 4) {
                    Text(monthYearText)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
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
    let sessions: [WorkoutSession]
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
                    DayCell(date: date, isToday: Calendar.current.isDateInToday(date), sessions: sessions)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Full Month View

struct FullMonthView: View {
    let month: Date
    let sessions: [WorkoutSession]
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
                ForEach(["М", "Т", "С", "Ч", "П", "С", "В"], id: \.self) { day in
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
                                DayCell(date: date, isToday: Calendar.current.isDateInToday(date), sessions: sessions)
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
    let sessions: [WorkoutSession]
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var hasWorkout: Bool {
        sessions.contains { session in
            Calendar.current.isDate(session.date, inSameDayAs: date) && session.isCompleted
        }
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
                        }
                    }
                )
                .cornerRadius(18)
            
            // Иконка тренировки или отдыха
            if hasWorkout {
                // Иконка гантели для дня с тренировкой
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
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
