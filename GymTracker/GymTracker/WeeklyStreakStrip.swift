//
//  WeeklyStreakStrip.swift
//  GymTracker
//
//  Weekly streak card for the dashboard. Replaces the old "days in a row"
//  metric (which was misleading for a gym app — nobody trains every day)
//  with an industry-standard weekly streak: consecutive weeks where the
//  user hit their training goal. Also surfaces Apple Fitness activity
//  (cardio, yoga, recovery) as colored markers so the weekly view shows
//  the user's full activity picture, not just Body Forge sessions.
//

import SwiftUI
import HealthKit

struct WeeklyStreakStrip: View {
    let sessions: [WorkoutSession]
    let externalWorkouts: [ExternalWorkout]
    /// Weekly training goal (number of strength sessions / week). Auto-derived
    /// from the active program in the dashboard, fallback 3.
    let weeklyGoal: Int

    @State private var selectedDay: Date?

    // MARK: - Calendar

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.currentLocale
        cal.firstWeekday = 2 // Monday
        return cal
    }

    // MARK: - Day classification

    /// Visual category for one calendar day. Order matters: a day with both
    /// gym and cardio shows up as `.combined` (rendered with a small badge).
    enum DayKind: Equatable {
        case gym                // Body Forge own session (counts toward goal)
        case externalStrength   // HK strength outside Body Forge (counts toward goal)
        case cardio             // run/walk/cycle/swim/HIIT — marked, doesn't count
        case recovery           // yoga/pilates/stretch — marked, doesn't count
        case combined           // gym + cardio/recovery same day
        case empty
        case future
    }

    /// Days the user logged a Body Forge session (start-of-day buckets).
    private var ownDays: Set<Date> {
        Set(sessions.map { calendar.startOfDay(for: $0.date) })
    }

    /// External activities bucketed by day.
    private var externalByDay: [Date: [ExternalWorkout]] {
        Dictionary(grouping: externalWorkouts) { calendar.startOfDay(for: $0.startDate) }
    }

    private func kind(for day: Date) -> DayKind {
        let d = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())
        if d > today { return .future }

        let hasGym = ownDays.contains(d)
        let externals = externalByDay[d] ?? []
        let hasExtStrength = externals.contains { Self.isStrength($0.activityType) }
        let hasCardio = externals.contains { Self.isCardio($0.activityType) }
        let hasRecovery = externals.contains { Self.isRecovery($0.activityType) }

        let strength = hasGym || hasExtStrength
        let activity = hasCardio || hasRecovery

        if strength && activity { return .combined }
        if hasGym               { return .gym }
        if hasExtStrength       { return .externalStrength }
        if hasCardio            { return .cardio }
        if hasRecovery          { return .recovery }
        return .empty
    }

    private static func isStrength(_ t: HKWorkoutActivityType) -> Bool {
        switch t {
        case .traditionalStrengthTraining, .functionalStrengthTraining,
             .crossTraining, .coreTraining:
            return true
        default: return false
        }
    }

    private static func isCardio(_ t: HKWorkoutActivityType) -> Bool {
        switch t {
        case .running, .walking, .hiking, .cycling, .swimming,
             .rowing, .elliptical, .stairClimbing, .stairs,
             .highIntensityIntervalTraining, .mixedCardio,
             .cardioDance, .dance, .wheelchairWalkPace, .wheelchairRunPace,
             .skatingSports, .surfingSports, .paddleSports,
             .waterFitness, .waterSports:
            return true
        default: return false
        }
    }

    private static func isRecovery(_ t: HKWorkoutActivityType) -> Bool {
        switch t {
        case .yoga, .pilates, .mindAndBody, .flexibility,
             .preparationAndRecovery, .cooldown:
            return true
        default: return false
        }
    }

    // MARK: - Week boundaries

    private func mondayOf(_ date: Date) -> Date {
        let d = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: d)
        let daysFromMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: d) ?? d
    }

    private var weekDays: [Date] {
        let monday = mondayOf(Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    // MARK: - Goal tracking

    /// Number of qualifying (strength) sessions in the given week.
    private func qualifyingCount(weekStarting monday: Date) -> Int {
        let end = calendar.date(byAdding: .day, value: 7, to: monday) ?? monday
        let ownInWeek = sessions.filter { $0.date >= monday && $0.date < end }.count
        let extStrength = externalWorkouts.filter {
            $0.startDate >= monday && $0.startDate < end && Self.isStrength($0.activityType)
        }
        // De-dupe per day so a day with both Body Forge + Apple strength counts once
        var days = Set<Date>()
        for s in sessions where s.date >= monday && s.date < end {
            days.insert(calendar.startOfDay(for: s.date))
        }
        for ext in extStrength {
            days.insert(calendar.startOfDay(for: ext.startDate))
        }
        return max(days.count, ownInWeek)
    }

    private var thisWeekCount: Int { qualifyingCount(weekStarting: mondayOf(Date())) }

    private var goalMet: Bool { thisWeekCount >= weeklyGoal }

    /// Weeks-in-a-row streak. Walks back week-by-week from the most recent
    /// completed week, adding 1 per week that meets the goal. The current
    /// week is added on top if already complete (so an in-progress week
    /// doesn't break the streak).
    private var weekStreak: Int {
        var count = goalMet ? 1 : 0
        var cursor = calendar.date(byAdding: .day, value: -7, to: mondayOf(Date())) ?? Date()
        var freezeAvailable = StreakFreezeStorage.shared.isAvailableThisMonth()
        let horizon = calendar.date(byAdding: .weekOfYear, value: -52, to: Date()) ?? Date()
        while cursor >= horizon {
            let q = qualifyingCount(weekStarting: cursor)
            if q >= weeklyGoal {
                count += 1
            } else if freezeAvailable {
                count += 1
                freezeAvailable = false
                StreakFreezeStorage.shared.consume() // 1/month auto-protect
            } else {
                break
            }
            cursor = calendar.date(byAdding: .day, value: -7, to: cursor) ?? cursor
            if count > 200 { break } // safety
        }
        return count
    }

    private var freezeUsedThisMonth: Bool {
        !StreakFreezeStorage.shared.isAvailableThisMonth()
    }

    // MARK: - Danger detection

    /// We're "in danger" if it's Thu+ and remaining strength sessions to goal
    /// is greater than the days remaining in the week.
    private var dangerHint: String? {
        guard !goalMet else { return nil }
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // weekday: Sunday=1, Monday=2, ... Saturday=7
        let daysRemaining = max(0, 8 - ((weekday + 5) % 7) - 1) // incl. today
        let remainingToGoal = weeklyGoal - thisWeekCount
        guard remainingToGoal > 0 else { return nil }
        let isLateInWeek = ((weekday + 5) % 7) >= 3 // Thu+
        guard isLateInWeek else { return nil }
        if remainingToGoal >= daysRemaining {
            return String(
                format: "До цели %d · осталось %d %@".localized(),
                remainingToGoal, daysRemaining, dayWord(daysRemaining)
            )
        }
        return nil
    }

    private func dayWord(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день".localized() }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня".localized() }
        return "дней".localized()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekRow
            if let hint = dangerHint {
                dangerBanner(hint)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(DesignSystem.Colors.neonGreen.opacity(goalMet ? 0.32 : 0.18),
                        lineWidth: goalMet ? 1.0 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: DesignSystem.Colors.neonGreen.opacity(goalMet ? 0.22 : 0.12),
                radius: goalMet ? 18 : 14, x: 0, y: 6)
        .sheet(item: Binding(
            get: { selectedDay.map { DayContext(date: $0) } },
            set: { selectedDay = $0?.date }
        )) { ctx in
            DayDetailsSheet(
                date: ctx.date,
                ownSessions: sessions.filter { calendar.isDate($0.date, inSameDayAs: ctx.date) },
                externals: externalByDay[calendar.startOfDay(for: ctx.date)] ?? []
            )
            .presentationDetents([.fraction(0.45), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: weekStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, DesignSystem.Colors.neonGreen],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(weekStreak)")
                        .font(DesignSystem.Typography.monospaced(.title, weight: .heavy))
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text(weekWord(weekStreak))
                        .font(DesignSystem.Typography.callout())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    if freezeUsedThisMonth {
                        Image(systemName: "snowflake")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 0.55, green: 0.85, blue: 1.0))
                            .padding(.leading, 2)
                            .accessibilityLabel(Text("Заморозка серии использована".localized()))
                    }
                }
                Text("ПОДРЯД".localized())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.4)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(thisWeekCount)")
                        .font(DesignSystem.Typography.monospaced(.title2, weight: .heavy))
                        .foregroundStyle(goalMet ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.primaryText)
                    Text("/\(weeklyGoal)")
                        .font(DesignSystem.Typography.monospaced(.body, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
                Text((goalMet ? "цель выполнена" : "на этой неделе").localized().uppercased())
                    .font(DesignSystem.Typography.sectionHeader())
                    .tracking(1.0)
                    .foregroundStyle(goalMet ? DesignSystem.Colors.neonGreen.opacity(0.85) : DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Week row

    private var weekRow: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                dayPill(day)
            }
        }
    }

    private func dayPill(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let dKind = kind(for: day)
        let main = mainColor(dKind)
        let isFilled = dKind == .gym || dKind == .externalStrength || dKind == .combined ||
                       dKind == .cardio || dKind == .recovery
        let countsToGoal = dKind == .gym || dKind == .externalStrength ||
                           (dKind == .combined) // combined always implies strength + activity

        return VStack(spacing: 6) {
            Text(weekdayLetter(day))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isToday ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText)

            ZStack {
                Circle()
                    .fill(pillFill(kind: dKind))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(
                                dKind == .externalStrength ? main.opacity(0.9) : Color.clear,
                                style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2])
                            )
                    )

                switch dKind {
                case .gym, .combined:
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.black)
                case .externalStrength:
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(main)
                case .cardio:
                    Image(systemName: "figure.run")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black.opacity(0.85))
                case .recovery:
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black.opacity(0.85))
                case .empty:
                    if isToday {
                        Circle()
                            .fill(DesignSystem.Colors.neonGreen)
                            .frame(width: 6, height: 6)
                    }
                case .future:
                    EmptyView()
                }

                // "+" badge for combined days (gym + extra Apple activity)
                if dKind == .combined {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(.black)
                        )
                        .offset(x: 12, y: -12)
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
            .accessibilityLabel(accessibilityLabel(for: day, kind: dKind))
            .accessibilityAddTraits(.isButton)

            // Tiny tag under the dot showing what kind of activity it was
            // (only for non-empty / non-future)
            if isFilled {
                Text(dotCaption(dKind))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(countsToGoal ? main.opacity(0.95) : main.opacity(0.75))
                    .lineLimit(1)
                    .frame(height: 10)
            } else {
                Spacer().frame(height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.35) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedDay = day
        }
    }

    private func mainColor(_ kind: DayKind) -> Color {
        switch kind {
        case .gym, .combined:
            return DesignSystem.Colors.neonGreen
        case .externalStrength:
            return DesignSystem.Colors.neonGreen
        case .cardio:
            return Color(red: 0.45, green: 0.85, blue: 1.0)
        case .recovery:
            return Color(red: 0.7, green: 0.55, blue: 1.0)
        case .empty, .future:
            return Color.white.opacity(0.35)
        }
    }

    private func pillFill(kind: DayKind) -> AnyShapeStyle {
        switch kind {
        case .gym, .combined:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [DesignSystem.Colors.neonGreen, Color(red: 0.6, green: 0.9, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .externalStrength:
            // Hollow with dashed outline (visual: "credit toward goal but logged elsewhere")
            return AnyShapeStyle(DesignSystem.Colors.neonGreen.opacity(0.12))
        case .cardio:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.45, green: 0.85, blue: 1.0),
                             Color(red: 0.25, green: 0.6, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .recovery:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.7, green: 0.55, blue: 1.0),
                             Color(red: 0.5, green: 0.35, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .future:
            return AnyShapeStyle(Color.white.opacity(0.04))
        case .empty:
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
    }

    private func dotCaption(_ kind: DayKind) -> String {
        switch kind {
        case .gym:              return "зал".localized()
        case .externalStrength: return "Силовая".localized()
        case .cardio:           return "Кардио".localized()
        case .recovery:         return "Йога".localized()
        case .combined:         return "Микс".localized()
        case .empty, .future:   return ""
        }
    }

    private func accessibilityLabel(for day: Date, kind: DayKind) -> Text {
        let df = DateFormatter()
        df.locale = LanguageManager.shared.currentLocale
        df.dateStyle = .full
        let dayStr = df.string(from: day)
        let stateStr: String
        switch kind {
        case .gym:              stateStr = "Тренировка в зале".localized()
        case .externalStrength: stateStr = "Силовая (Apple Fitness)".localized()
        case .cardio:           stateStr = "Кардио".localized()
        case .recovery:         stateStr = "Восстановление".localized()
        case .combined:         stateStr = "Зал + активность".localized()
        case .empty:            stateStr = "Нет активности".localized()
        case .future:           stateStr = "Ещё не наступил".localized()
        }
        return Text("\(dayStr), \(stateStr)")
    }

    // MARK: - Danger banner

    private func dangerBanner(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Color.orange)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Color.orange.opacity(0.35), lineWidth: 0.5))
    }

    // MARK: - Helpers

    private func weekdayLetter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "EE"
        let raw = formatter.string(from: date)
        return String(raw.prefix(2)).uppercased()
    }

    private func weekWord(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "Неделя".localized() }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "Недели".localized() }
        return "Недель".localized()
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
                colors: [DesignSystem.Colors.neonGreen.opacity(goalMet ? 0.18 : 0.10), .clear],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 220
            )
        }
    }
}

// MARK: - Streak Freeze persistence

/// 1 auto-protect per calendar month. The freeze is silently consumed when
/// the streak walker encounters a missed week — user gets the benefit without
/// having to opt in. Resets when the calendar month rolls over.
final class StreakFreezeStorage {
    static let shared = StreakFreezeStorage()
    private let key = "weeklyStreakFreezeUsedMonth"
    private init() {}

    private var currentMonthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.calendar = Calendar(identifier: .gregorian)
        return f.string(from: Date())
    }

    func isAvailableThisMonth() -> Bool {
        let used = UserDefaults.standard.string(forKey: key)
        return used != currentMonthKey
    }

    func consume() {
        UserDefaults.standard.set(currentMonthKey, forKey: key)
    }
}

// MARK: - Day details sheet (long-press)

private struct DayContext: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

private struct DayDetailsSheet: View {
    let date: Date
    let ownSessions: [WorkoutSession]
    let externals: [ExternalWorkout]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.currentLocale
        return cal
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: date).capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if ownSessions.isEmpty && externals.isEmpty {
                        emptyState
                    } else {
                        if !ownSessions.isEmpty {
                            sectionHeader("Body Forge".localized())
                            ForEach(ownSessions, id: \.id) { s in
                                ownRow(s)
                            }
                        }
                        if !externals.isEmpty {
                            sectionHeader("Apple Fitness".localized())
                            ForEach(externals, id: \.id) { ext in
                                externalRow(ext)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey(dateLabel))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("День отдыха".localized())
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text("Активности не зафиксировано".localized())
                .font(.subheadline)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(LocalizedStringKey(text)).font(.system(size: 11, weight: .heavy))
            .tracking(1.2)
            .foregroundStyle(DesignSystem.Colors.tertiaryText)
            .padding(.top, 4)
    }

    private func ownRow(_ s: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 36, height: 36)
                .background(DesignSystem.Colors.neonGreen, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(s.workoutDayName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                Text(timeRange(start: s.date, end: s.endTime))
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func externalRow(_ ext: ExternalWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ext.iconName)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 36, height: 36)
                .background(ext.tint, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(ext.displayName))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                HStack(spacing: 8) {
                    Text(ext.formattedDuration)
                    if let dist = ext.formattedDistance { Text("· \(dist)") }
                    if let kcal = ext.totalEnergyBurnedKcal, kcal > 0 {
                        Text("· \(Int(kcal)) \("ккал".localized())")
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                Text(LocalizedStringKey(ext.sourceName))
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func timeRange(start: Date, end: Date?) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.currentLocale
        f.dateFormat = "HH:mm"
        let from = f.string(from: start)
        guard let end, end > start else { return from }
        let to = f.string(from: end)
        return "\(from) – \(to)"
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WeeklyStreakStrip(sessions: [], externalWorkouts: [], weeklyGoal: 3)
            .padding()
    }
}
