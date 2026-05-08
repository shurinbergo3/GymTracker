//
//  WorkoutDashboardViews.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Combine
import Charts
import HealthKit

// MARK: - Sleep Data Model

// MARK: - Sleep Analysis UI



// MARK: - Today's Workout Card (Dynamic State)

struct TodayWorkoutCard: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Binding var showingDaySelection: Bool
    var onOpenWorkout: () -> Void
    
    var body: some View {
        BentoCard {
            if workoutManager.workoutState == .active {
                // Active Workout State
                activeWorkoutContent
            } else {
                // Idle State - Start Workout
                idleContent
            }
        }
    }
    
    // MARK: - Idle State (Start Workout)
    private var idleContent: some View {
        ZStack(alignment: .topTrailing) {
            // Subtle neon mesh accents
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 220
            )
            .allowsHitTesting(false)

            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.14), .clear],
                center: .bottomLeading,
                startRadius: 4,
                endRadius: 200
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header row with bright "TODAY" tag + day selector
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(DesignSystem.Colors.neonGreen)
                                .frame(width: 6, height: 6)
                                .shadow(color: DesignSystem.Colors.neonGreen, radius: 4)
                            Text("План на сегодня".localized().localizedUppercase)
                                .font(DesignSystem.Typography.sectionHeader())
                                .foregroundStyle(DesignSystem.Colors.neonGreen)
                                .tracking(1.4)
                        }

                        if let day = workoutManager.selectedDay {
                            Text(day.name.localized())
                                .font(DesignSystem.Typography.title())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("rest_day_title".localized())
                                .font(DesignSystem.Typography.title())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                        }
                    }

                    Spacer()

                    Button(action: { showingDaySelection = true }) {
                        Image(systemName: "list.dash")
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(DesignSystem.Colors.neonGreen.opacity(0.12))
                            )
                            .overlay(
                                Circle().stroke(DesignSystem.Colors.neonGreen.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.45), radius: 12)
                    }
                }

                // Unified stats strip
                if let day = workoutManager.selectedDay {
                    HStack(spacing: 0) {
                        statColumn(
                            icon: "dumbbell.fill",
                            iconTint: DesignSystem.Colors.neonGreen,
                            value: "\(day.exercises.count)",
                            label: "упр.".localized()
                        )
                        statColumnDivider
                        statColumn(
                            icon: "list.number",
                            iconTint: Color(red: 0.45, green: 0.85, blue: 1.0),
                            value: "\(estimatedSets(for: day))",
                            label: "подходов".localized()
                        )
                        statColumnDivider
                        statColumn(
                            icon: "clock.fill",
                            iconTint: Color(red: 1.0, green: 0.7, blue: 0.2),
                            value: "~\(estimatedMinutes(for: day))",
                            label: "мин".localized()
                        )
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // Start Button — compact neon CTA
                Button(action: { workoutManager.startWorkout() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(.black.opacity(0.18)))
                            .offset(x: 0.5)
                        Text(workoutManager.selectedDay == nil ? "select_program_button".localized() : "start_workout_button".localized())
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .tracking(0.3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.neonGreen,
                                    Color(red: 0.6, green: 0.9, blue: 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.30), lineWidth: 0.5)
                    )
                    .foregroundStyle(.black)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.40), radius: 14, x: 0, y: 6)
                }
                .disabled(workoutManager.selectedDay == nil)
                .opacity(workoutManager.selectedDay == nil ? 0.55 : 1)
                .accessibilityIdentifier("btn_start_workout")
            }
        }
    }

    @ViewBuilder
    private func statColumn(icon: String, iconTint: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(iconTint)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statColumnDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 1, height: 32)
    }

    private func estimatedSets(for day: WorkoutDay) -> Int {
        // Defensive: skip SwiftData zombies (relationship still references a row
        // whose backing data is gone — accessing properties would fatalError).
        day.exercises
            .filter { $0.modelContext != nil }
            .reduce(0) { $0 + max(1, $1.plannedSets) }
    }

    private func estimatedMinutes(for day: WorkoutDay) -> Int {
        // Rough heuristic: 4 min per set including rest
        max(15, estimatedSets(for: day) * 4)
    }
    
    // MARK: - Active State (Workout In Progress)
    private var activeWorkoutContent: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("workout_active_label".localized().localizedUppercase)
                            .font(DesignSystem.Typography.sectionHeader())
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                            .tracking(1.2)
                        
                        if let day = workoutManager.selectedDay {
                            Text(day.name.localized())
                                .font(DesignSystem.Typography.title2())
                                .foregroundStyle(DesignSystem.Colors.primaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Pulsing indicator
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 10, height: 10)
                        .shadow(color: DesignSystem.Colors.neonGreen, radius: 10)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.neonGreen.opacity(0.4), lineWidth: 3)
                                .scaleEffect(1.5)
                        )
                }
                
                // Stats Row
                HStack(spacing: 20) {
                    // Timer
                    VStack(alignment: .leading, spacing: 2) {
                        Label("time_label".localized(), systemImage: "timer")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                        Text(formatElapsedTime(context.date))
                            .font(DesignSystem.Typography.monospaced(.title2, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Exercises Progress
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("progress_label".localized(), systemImage: "checkmark.circle")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                        Text(progressText)
                            .font(DesignSystem.Typography.monospaced(.title3, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                    }
                    
                    // Calories
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("calories_label".localized(), systemImage: "flame.fill")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                        Text("\(workoutManager.currentActiveCalories)")
                            .font(DesignSystem.Typography.monospaced(.title3, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(colors: [DesignSystem.Colors.neonGreen, Color(red: 0.6, green: 0.9, blue: 0.15)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * progressPercentage, height: 8)
                            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.3), radius: 5)
                    }
                }
                .frame(height: 8)
                
                // Tap to View Button
                Button(action: onOpenWorkout) {
                    HStack {
                        Spacer()
                        Text("open_workout_button".localized())
                            .font(DesignSystem.Typography.headline())
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatElapsedTime(_ currentDate: Date) -> String {
        guard let startDate = workoutManager.currentSession?.date else { return "00:00" }
        let elapsed = currentDate.timeIntervalSince(startDate)
        
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressText: String {
        guard let session = workoutManager.currentSession,
              let day = workoutManager.selectedDay else { return "0/0" }
        
        let totalExercises = day.exercises.count
        let completedExercises = Set(session.sets.map { $0.exerciseName }).count
        
        return "\(completedExercises)/\(totalExercises)"
    }
    
    private var progressPercentage: CGFloat {
        guard let session = workoutManager.currentSession,
              let day = workoutManager.selectedDay,
              day.exercises.count > 0 else { return 0 }
        
        let totalSets = day.exercises
            .filter { $0.modelContext != nil }
            .reduce(0) { $0 + $1.plannedSets }
        let completedSets = session.sets.count
        
        return min(1.0, CGFloat(completedSets) / CGFloat(max(1, totalSets)))
    }
}

struct SleepDetailView: View {
    let sleepData: [SleepData]
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRange: SleepTimeRange = .day
    @State private var historyData: [DailySleepData] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Range Picker
                    Picker("period_picker_label".localized(), selection: $selectedRange) {
                        ForEach(SleepTimeRange.allCases) { range in
                            Text(range.localizedName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedRange == .day {
                        // MARK: - Day View (Original)
                        dayViewContent
                    } else {
                        // MARK: - History View (New)
                        historyViewContent
                    }
                }
                .padding(.vertical)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("sleep_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done_button".localized()) { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }
            .onChange(of: selectedRange) { _, newRange in
                if newRange != .day {
                    Task {
                    Task {
                        // Use SleepService
                        self.historyData = await SleepService.shared.fetchSleepHistory(for: newRange)
                    }
                    }
                }
            }
        }
    }
    
    // MARK: - Day Content
    private var dayViewContent: some View {
        VStack(spacing: 24) {
            // Header Stats
            HStack(spacing: 20) {
                SleepStatBox(title: "total_sleep_stat".localized(), value: formatDuration(totalSleep), color: .white)
                SleepStatBox(title: "in_bed_stat".localized(), value: formatDuration(totalInBed), color: .gray)
            }
            .padding(.horizontal)
            
            // Main Graph
            VStack(alignment: .leading, spacing: 16) {
                Text("sleep_stages_today".localized())
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Chart {
                    ForEach(sleepData) { datum in
                        BarMark(
                            x: .value("Time", datum.startDate ..< datum.endDate),
                            y: .value("Stage", datum.label) // Converted to helper or extension
                        )
                        .foregroundStyle(datum.color) // Converted to helper or extension
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .extended, position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 300)
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Legend / Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("details_section".localized())
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)
                
                SleepLegendRow(color: .purple, label: "deep_sleep_legend".localized(), duration: duration(for: .asleepDeep))
                Divider().background(Color.gray.opacity(0.3))
                SleepLegendRow(color: .blue, label: "core_sleep_legend".localized(), duration: duration(for: .asleepCore))
                Divider().background(Color.gray.opacity(0.3))
                SleepLegendRow(color: .cyan, label: "rem_sleep_legend".localized(), duration: duration(for: .asleepREM))
                Divider().background(Color.gray.opacity(0.3))
                SleepLegendRow(color: .orange, label: "awake_sleep_legend".localized(), duration: duration(for: .awake))
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // MARK: - History Content
    private var historyViewContent: some View {
        VStack(spacing: 24) {
            // Avg Stats
            let avgSleep = historyData.isEmpty ? 0 : historyData.reduce(0) { $0 + $1.totalDuration } / Double(historyData.count)
            
            HStack(spacing: 20) {
                SleepStatBox(title: "avg_sleep_stat".localized(), value: formatDuration(avgSleep), color: .white)
                // Placeholder for second stat or remove
                Spacer()
            }
            .padding(.horizontal)
            
            // History Graph
            VStack(alignment: .leading, spacing: 16) {
                Text("\("history_title".localized()) (\(selectedRange.rawValue))")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if historyData.isEmpty {
                    Text("no_data_period".localized())
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Chart {
                        ForEach(historyData) { datum in
                            BarMark(
                                x: .value("Date", datum.date, unit: .day),
                                y: .value("Hours", datum.totalDuration / 3600.0) // Convert to Hours
                            )
                            .foregroundStyle(DesignSystem.Colors.neonGreen.gradient)
                        }
                        
                        // RuleMark for Goal (e.g. 8h)
                        RuleMark(y: .value("Goal", 8))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(.purple.opacity(0.5))
                            .annotation(position: .leading) {
                                Text("8ч".localized())
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel()
                                .foregroundStyle(.gray)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: selectedRange == .week ? 7 : 5)) { value in
                            AxisValueLabel(format: .dateTime.day().month())
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(height: 300)
                }
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // Helpers
    private var totalSleep: TimeInterval {
        let filtered = sleepData.filter {
            $0.type == .asleepCore ||
            $0.type == .asleepDeep ||
            $0.type == .asleepREM ||
            $0.type == .asleepUnspecified
        }.sorted { $0.startDate < $1.startDate }
        
        return SleepService.calculateTotalDuration(from: filtered)
    }
    
    private var totalInBed: TimeInterval {
        let filtered = sleepData.filter { $0.type == .inBed }
            .sorted { $0.startDate < $1.startDate }
        
        return SleepService.calculateTotalDuration(from: filtered)
    }
    
    private func duration(for type: HKCategoryValueSleepAnalysis) -> TimeInterval {
        let filtered = sleepData.filter { $0.type == type }
            .sorted { $0.startDate < $1.startDate }
        
        return SleepService.calculateTotalDuration(from: filtered)
    }
    

    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)\("ч".localized()) \(minutes)\("м".localized())"
    }
}

struct SleepStatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
    }
}

struct SleepLegendRow: View {
    let color: Color
    let label: String
    let duration: TimeInterval
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundStyle(.white)
                .font(.callout)
            Spacer()
            Text(formatDuration(duration))
                .foregroundStyle(.gray)
                .font(.callout)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)\("ч".localized()) \(minutes)\("м".localized())"
    }
}

// MARK: - Dashboard View (Idle State)

struct DashboardView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingDaySelection = false
    @State private var showingCalendarSheet = false
    @State private var showingAchievementsSheet = false
    @State private var showingAppleHealthSheet = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// Manual override for weekly training target. `0` (default) means
    /// auto-derive from active program. Stored globally so streak/achievements
    /// stay in sync.
    @AppStorage("weeklyWorkoutGoal") private var weeklyGoalOverride: Int = 0

    // CRITICAL FIX: Limit query to prevent freeze with large datasets
    @State private var history: [WorkoutSession] = []
    @State private var totalCompletedCount: Int = 0
    @State private var weeklyWrapped: WeeklyWrappedSnapshot?
    @State private var externalWorkouts: [ExternalWorkout] = []
    /// Wider window (12 weeks) used by the weekly-streak card so it can
    /// compute weeks-in-a-row correctly. Kept separate from `externalWorkouts`,
    /// which is intentionally limited to the last 7 days for the
    /// AppleHealthActivityCard surface.
    @State private var externalWorkoutsForStreak: [ExternalWorkout] = []

    private var recentHistory: [WorkoutSession] {
        Array(history.prefix(1))
    }

    private var previousSession: WorkoutSession? {
        history.dropFirst().first
    }

    private var daysSinceLastWorkout: Int {
        guard let lastDate = history.first?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }

    private var workoutsThisWeek: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return history.filter { $0.date >= monday }.count
    }

    /// Weekly training target. Priority: explicit user setting (1…7) →
    /// program cycle length (capped at 6 for one rest day) → 3.
    /// `weeklyGoalOverride == 0` means "follow program" — that's the default
    /// and matches old behavior so existing users see no change unless they
    /// opt in via Settings.
    private var weeklyGoal: Int {
        if weeklyGoalOverride >= 1 { return min(7, weeklyGoalOverride) }
        if let program = workoutManager.activeProgram {
            let count = program.days.count
            if count > 0 { return min(6, max(1, count)) }
        }
        return 3
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Weekly streak strip — tap to open full calendar.
                // Long-press on any day pill opens that day's details inline.
                Button {
                    showingCalendarSheet = true
                } label: {
                    WeeklyStreakStrip(
                        sessions: history,
                        externalWorkouts: externalWorkoutsForStreak,
                        weeklyGoal: weeklyGoal
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DesignSystem.Spacing.lg)

                // Weekly Wrapped — Spotify-style end-of-week recap. Only surfaces
                // once there's at least one workout in the current week, so a
                // brand-new user doesn't see an empty stat reel.
                if workoutsThisWeek > 0 {
                    WeeklyWrappedTeaser {
                        weeklyWrapped = WeeklyWrappedGenerator.make(modelContext: modelContext)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }

                // MARK: - Today's Plan (Action Hero Card)
                TodayWorkoutCard(
                    workoutManager: workoutManager,
                    showingDaySelection: $showingDaySelection,
                    onOpenWorkout: { }
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)

                // NEW: AI Coach widget (post-workout recommendations)
                AICoachWidget(
                    lastSession: recentHistory.first,
                    previousSession: previousSession
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)

                // Кольца активности — отдельной секцией. Показываются всегда,
                // пока Apple Watch включены в настройках (нативный HKActivityRingView
                // сам отрисует пустые кольца до прихода данных).
                ActivityRingsSection()
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))

                // Apple Health — non-app workouts (walks, cycling, yoga,
                // third-party trackers). Hidden if user revoked HK access
                // OR has no external workouts in the last 7 days.
                if !externalWorkouts.isEmpty {
                    AppleHealthActivityCard(workouts: externalWorkouts) {
                        showingAppleHealthSheet = true
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }

                // Last Workout Preview (moved to main column)
                if let lastSession = recentHistory.first {
                    NavigationLink(destination: WorkoutHistoryDetailView(session: lastSession)) {
                        LastWorkoutBento(session: lastSession)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }

                Spacer().frame(height: 100)
            }
        }
        .task {
            await reloadDashboardData()
        }
        // HealthKit syncs from Apple Watch can lag the app's first launch by
        // 30+ seconds. The HKObserverQuery in HealthManager posts on every
        // sync — refresh both windows so streak/cards aren't stuck on stale
        // data while the user sits on the dashboard.
        .onReceive(NotificationCenter.default.publisher(for: .healthKitWorkoutsDidChange)) { _ in
            Task { await refreshExternalWorkouts() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refreshExternalWorkouts() }
            }
        }
        .sheet(isPresented: $showingDaySelection) {
            if let program = workoutManager.activeProgram {
                DaySelectionSheet(
                    program: program,
                    selectedDay: $workoutManager.selectedDay
                )
                .environmentObject(workoutManager)
            }
        }
        .sheet(isPresented: $showingCalendarSheet) {
            CalendarSheet()
        }
        .sheet(isPresented: $showingAchievementsSheet) {
            ProgressHubView()
        }
        .sheet(isPresented: $showingAppleHealthSheet) {
            AppleHealthWorkoutsSheet(workouts: externalWorkouts)
        }
        .fullScreenCover(item: $weeklyWrapped) { snapshot in
            WeeklyWrappedView(snapshot: snapshot, onClose: { weeklyWrapped = nil })
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }

    // Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Initial dashboard load: SwiftData history + count + both HK windows.
    /// Called from `.task` on first appear; also re-runs on each subsequent
    /// appearance because `.task` is tied to view lifecycle.
    private func reloadDashboardData() async {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 100

        if let fetchedHistory = try? modelContext.fetch(descriptor) {
            await MainActor.run { self.history = fetchedHistory }
        }

        var countDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true }
        )
        countDescriptor.fetchLimit = 0
        if let total = try? modelContext.fetchCount(countDescriptor) {
            await MainActor.run { self.totalCompletedCount = total }
        }

        await refreshExternalWorkouts()
    }

    /// Re-fetches both HK windows (last 7 days for the AppleHealthActivityCard,
    /// last 12 weeks for the streak walker). Called on HK observer notifications,
    /// scene becoming active, and as part of the initial load. HealthManager
    /// short-circuits when not authorized, so this is cheap when HK is off.
    private func refreshExternalWorkouts() async {
        let external = await HealthManager.shared.fetchExternalWorkoutsThisWeek()
        let now = Date()
        let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: now) ?? now
        let externalForStreak = await HealthManager.shared.fetchExternalWorkouts(from: twelveWeeksAgo, to: now)

        await MainActor.run {
            self.externalWorkouts = external
            self.externalWorkoutsForStreak = externalForStreak
        }
    }
}

// MARK: - Premium Bento Card (Gradient + Glow)
struct PremiumBentoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGray6).opacity(0.15),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [DesignSystem.Colors.neonGreen.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.1), radius: 10, x: 0, y: 0)
    }
}

// MARK: - History Card View
struct HistoryCardView: View {
    let session: WorkoutSession
    
    var body: some View {
        // Plain card content, interaction moved to parent
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Day Name (Big)
                Text(session.workoutDayName.localized())
                    .font(.headline)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                // Program Name (Small)
                if let programName = session.programName {
                    Text(programName.localized())
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.primaryText.opacity(0.7))
                }
                
                // Date & Day (Small Gray)
                Text(formatDateFull(session.date))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Stats + Arrow
            VStack(alignment: .trailing, spacing: 4) {
                if let calories = session.calories {
                    Text("\(calories) \("ккал".localized())")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
                
                // Growth Arrow (Visual only for now, or simplified logic)
                Image(systemName: "arrow.up") // Placeholder for growth, logic needs expensive fetch
                    .font(.headline)
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.leading, 8)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM, EEEEE" // 16 янв, П
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Sparkline Graph
struct SparklineGraph: Shape {
    let data: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }
        
        let stepX = rect.width / CGFloat(data.count - 1)
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 1
        let range = maxVal - minVal
        
        // Helper to normalize
        func yPosition(for value: Double) -> CGFloat {
            let normalized = (value - minVal) / (range == 0 ? 1 : range)
            return rect.height - (CGFloat(normalized) * rect.height)
        }
        
        path.move(to: CGPoint(x: 0, y: yPosition(for: data[0])))
        
        for index in 1..<data.count {
            let x = CGFloat(index) * stepX
            let y = yPosition(for: data[index])
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Today's Plan Card

struct TodaysPlanCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var showingDaySelection: Bool
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                // Header
                Text("План на сегодня".localized())
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                // Day selector
                if let selectedDay = workoutManager.selectedDay {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(selectedDay.name.localized())
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("\(selectedDay.exercises.count) \("упражнений".localized())")
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingDaySelection = true }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                        }
                    }
                } else {
                    Text("Выберите тренировку".localized())
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Start button
                GradientButton(title: "Начать тренировку".localized(), icon: "play.fill") {
                    workoutManager.startWorkout()
                }
            }
            .padding(DesignSystem.Spacing.xxl)
        }
        .sheet(isPresented: $showingDaySelection) {
            if let program = workoutManager.activeProgram {
                DaySelectionSheet(
                    program: program,
                    selectedDay: $workoutManager.selectedDay
                )
                .environmentObject(workoutManager)
            }
        }
    }
}

// MARK: - Previous Progress Card

struct PreviousProgressCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Прошлые успехи".localized())
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                let progressData = workoutManager.getPreviewProgressData()
                
                if progressData.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                        
                        Text("Нет данных".localized())
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("Выполните первую тренировку, чтобы отслеживать прогресс".localized())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.xl)
                } else {
                    ForEach(progressData.indices, id: \.self) { index in
                        ExerciseProgressRow(exerciseProgress: progressData[index])
                        
                        if index < progressData.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.secondaryText.opacity(0.2))
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Active Workout View

struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingCancelConfirmation = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Active Workout Bento Header
                    ActiveWorkoutHeader()
                        .environmentObject(workoutManager)
                        .id("top")

                    // Real-time gamification strip: sets progress + streak + PR flash
                    WorkoutProgressStrip()
                        .environmentObject(workoutManager)
                    
                    // Current workout card
                    if let selectedDay = workoutManager.selectedDay,
                       let programName = workoutManager.activeProgram?.name {
                        ActiveWorkoutContent(
                            workoutDay: selectedDay,
                            programName: programName
                        )
                        .environmentObject(workoutManager)
                        .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .onTapGesture {
                hideKeyboard()
            }
            .onAppear {
                // Scroll to top when workout starts (with slight delay for layout)
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .confirmationDialog(
                "cancel_workout_confirm".localized(),
                isPresented: $showingCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Отменить тренировку".localized(), role: .destructive) {
                    workoutManager.cancelWorkout()
                }
                Button("Продолжить".localized(), role: .cancel) { }
            } message: {
                Text("Данные текущей тренировки не будут сохранены.".localized())
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DestructiveCloseButton(action: { showingCancelConfirmation = true })
                }
            }
        }
    }
}

// MARK: - Summary Overlay

struct SummaryOverlay: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var notes = ""
    @State private var calories: Int = 0
    @State private var heartRate: Int = 0
    @State private var progressData: [ExerciseProgress] = []
    @State private var animateHero = false
    @State private var showingProgressHub = false

    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true },
           sort: \WorkoutSession.date, order: .reverse)
    private var completedSessions: [WorkoutSession]

    // MARK: - Computed metrics

    private var session: WorkoutSession? { workoutManager.currentSession }

    private var totalVolume: Double { session?.volume ?? 0 }

    private var setsCount: Int { session?.sets.count ?? 0 }

    private var totalReps: Int {
        session?.sets.reduce(0) { $0 + $1.reps } ?? 0
    }

    private var exercisesCount: Int {
        guard let session = session else { return 0 }
        return Set(session.sets.map { $0.exerciseName }).count
    }

    private var prCount: Int {
        progressData.filter { $0.progressState == .improved }.count
    }

    private var sessionDuration: TimeInterval {
        guard let s = session else { return 0 }
        return s.endTime?.timeIntervalSince(s.date) ?? 0
    }

    private var previousVolume: Double {
        guard let s = session else { return 0 }
        let prev = completedSessions.first { $0.id != s.id && $0.workoutDayName == s.workoutDayName }
        return prev?.volume ?? 0
    }

    private var volumeDeltaPercent: Int? {
        guard previousVolume > 0 else { return nil }
        let pct = ((totalVolume - previousVolume) / previousVolume) * 100
        return Int(pct.rounded())
    }

    private var streak: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.currentLocale
        var trained = Set(completedSessions.map { cal.startOfDay(for: $0.date) })
        if let s = session {
            trained.insert(cal.startOfDay(for: s.date))
        }
        var current = cal.startOfDay(for: Date())
        var count = 0
        if !trained.contains(current) {
            guard let y = cal.date(byAdding: .day, value: -1, to: current) else { return 0 }
            current = y
        }
        while trained.contains(current) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return count
    }

    private var historyIncludingCurrent: [WorkoutSession] {
        guard let s = session else { return completedSessions }
        if completedSessions.contains(where: { $0.id == s.id }) {
            return completedSessions
        }
        return [s] + completedSessions
    }

    private var totalWorkoutsIncludingCurrent: Int {
        historyIncludingCurrent.count
    }

    private var workoutsThisWeekIncludingCurrent: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return historyIncludingCurrent.filter { $0.date >= monday }.count
    }

    private var motivationalSubtitle: String {
        if prCount >= 3 { return "Невероятный результат! Новые рекорды!".localized() }
        if prCount > 0 { return "Ты растёшь! Только вперёд!".localized() }
        if let d = volumeDeltaPercent, d >= 5 {
            return "\("Объём вырос на".localized()) +\(d)%"
        }
        if streak >= 3 {
            return "\("Серия".localized()) \(streak) — \("так держать!".localized())"
        }
        return "Каждая тренировка приближает к цели".localized()
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    heroSection

                    if session != nil {
                        heroMetricCard
                        achievementStrip
                        compactStatsGrid

                        ActivityHeroSection(
                            totalWorkouts: totalWorkoutsIncludingCurrent,
                            workoutsThisWeek: workoutsThisWeekIncludingCurrent,
                            history: historyIncludingCurrent,
                            onTap: { showingProgressHub = true }
                        )
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        if !progressData.isEmpty {
                            exerciseBreakdown
                        }
                    }

                    notesEditor
                    saveButton

                    Spacer().frame(height: DesignSystem.Spacing.xxl)
                }
                .padding(.top, DesignSystem.Spacing.lg)
            }
        }
        .onAppear {
            loadSession()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.05)) {
                animateHero = true
            }
        }
        .sheet(isPresented: $showingProgressHub) {
            ProgressHubView()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.18))
                    .frame(width: 96, height: 96)
                    .blur(radius: 10)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.neonGreen, .green],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 16)
                    .scaleEffect(animateHero ? 1.0 : 0.4)
                    .opacity(animateHero ? 1.0 : 0)
            }

            Text("Тренировка завершена!".localized())
                .font(DesignSystem.Typography.title2())
                .foregroundColor(DesignSystem.Colors.primaryText)

            Text(motivationalSubtitle)
                .font(DesignSystem.Typography.subheadline())
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
    }

    // MARK: - Hero metric card (Tonnage)

    private var heroMetricCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.22),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.25), radius: 20)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                    Text("Поднято за тренировку".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundColor(DesignSystem.Colors.neonGreen.opacity(0.85))
                        .tracking(1.2)
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(formattedVolume(totalVolume))
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("кг".localized())
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                if let delta = volumeDeltaPercent {
                    HStack(spacing: 4) {
                        Image(systemName: delta > 0 ? "arrow.up.right" :
                                delta < 0 ? "arrow.down.right" : "equal")
                            .font(.caption2.bold())
                        Text(deltaText(delta))
                            .font(DesignSystem.Typography.caption().weight(.semibold))
                    }
                    .foregroundColor(deltaColor(delta))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(deltaColor(delta).opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .frame(height: 130)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Achievement strip (Streak / PR / Pulse)

    private var achievementStrip: some View {
        HStack(spacing: 10) {
            achievementCard(
                icon: "flame.fill",
                value: "\(streak)",
                unit: streak == 1 ? "день".localized() : "дней".localized(),
                title: "Серия".localized(),
                color: .orange,
                isOn: streak > 0
            )
            achievementCard(
                icon: "trophy.fill",
                value: "\(prCount)",
                unit: "новых".localized(),
                title: "Рекорды".localized(),
                color: DesignSystem.Colors.neonGreen,
                isOn: prCount > 0
            )
            achievementCard(
                icon: "heart.fill",
                value: heartRate > 0 ? "\(heartRate)" : "—",
                unit: "уд/мин".localized(),
                title: "Пульс".localized(),
                color: .red,
                isOn: heartRate > 0
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private func achievementCard(
        icon: String, value: String, unit: String,
        title: String, color: Color, isOn: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(isOn ? color : color.opacity(0.45))
                .shadow(color: isOn ? color.opacity(0.6) : .clear, radius: 6)

            Text(title.uppercased())
                .font(DesignSystem.Typography.sectionHeader())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .tracking(1.0)
                .lineLimit(1)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isOn ? color.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Compact stats grid (Time / Sets / Reps / Exercises)

    private var compactStatsGrid: some View {
        HStack(spacing: 8) {
            miniStat(icon: "clock.fill", color: .blue,
                     value: shortDuration(sessionDuration),
                     label: "Время".localized())
            miniStat(icon: "square.stack.3d.up.fill", color: .purple,
                     value: "\(setsCount)",
                     label: "Подходы".localized())
            miniStat(icon: "repeat", color: .cyan,
                     value: "\(totalReps)",
                     label: "Повторы".localized())
            miniStat(icon: "figure.strengthtraining.traditional", color: .pink,
                     value: "\(exercisesCount)",
                     label: "Упражнения".localized())
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private func miniStat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundColor(DesignSystem.Colors.primaryText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Exercise breakdown

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("ДЕТАЛИЗАЦИЯ".localized())
                    .font(DesignSystem.Typography.sectionHeader())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                Spacer()
                if prCount > 0 {
                    Text("+\(prCount) PR")
                        .font(DesignSystem.Typography.caption().weight(.bold))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            VStack(spacing: 6) {
                ForEach(progressData, id: \.exerciseName) { item in
                    breakdownRow(item)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }

    private func breakdownRow(_ item: ExerciseProgress) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(item.progressState.color)
                .frame(width: 3, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.exerciseName.localized())
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                Text(item.currentStats)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Spacer()

            Image(systemName: item.progressState.icon)
                .font(.caption.bold())
                .foregroundColor(item.progressState.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.progressState.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }

    // MARK: - Notes & Save

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header в стиле AI Coach: иконка-«сфера» + заголовок + подпись
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DesignSystem.Colors.accentPurple.opacity(0.55), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 32
                            )
                        )
                        .frame(width: 64, height: 64)
                        .blur(radius: 8)
                        .opacity(0.85)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accentPurple, DesignSystem.Colors.neonGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Комментарий о тренировке".localized())
                        .font(DesignSystem.Typography.title3())
                        .foregroundStyle(DesignSystem.Colors.primaryText)

                    Text("Заметка для AI-разбора".localized().uppercased())
                        .font(DesignSystem.Typography.sectionHeader())
                        .tracking(1.2)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
                Spacer()
            }

            // Bubble-поле ввода в стиле сообщения AI Coach
            HStack(alignment: .top, spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 3, height: 90)

                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Расскажите как прошла ваша тренировка".localized())
                            .font(DesignSystem.Typography.body())
                            .foregroundStyle(DesignSystem.Colors.secondaryText.opacity(0.5))
                            .padding(.top, 10)
                            .padding(.leading, 6)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .frame(height: 90)
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(notesCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(notesNeonStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .shadow(color: DesignSystem.Colors.accentPurple.opacity(0.25), radius: 20, x: 0, y: 8)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private var notesCardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.16),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [DesignSystem.Colors.accentPurple.opacity(0.18), .clear],
                center: .topLeading,
                startRadius: 4,
                endRadius: 220
            )
            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 4,
                endRadius: 240
            )
        }
    }

    private var notesNeonStroke: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.accentPurple.opacity(0.55),
                DesignSystem.Colors.neonGreen.opacity(0.35),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var saveButton: some View {
        GradientButton(title: "Закрыть и сохранить".localized(), icon: "checkmark.circle.fill") {
            if !notes.isEmpty {
                workoutManager.currentSession?.notes = notes
            }
            workoutManager.currentSession?.calories = calories
            workoutManager.currentSession?.averageHeartRate = heartRate
            workoutManager.closeWorkout()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Helpers

    private func loadSession() {
        guard let session = workoutManager.currentSession else { return }
        notes = session.notes ?? ""
        calories = session.calories ?? 0
        heartRate = session.averageHeartRate ?? 0

        if let program = workoutManager.activeProgram,
           let day = program.days.first(where: { $0.name == session.workoutDayName }) {
            let previousSession = workoutManager.getPreviousSession(for: day)
            progressData = workoutManager.getProgressData(for: session, comparedTo: previousSession)
        } else if let day = workoutManager.selectedDay, day.name == session.workoutDayName {
            let previousSession = workoutManager.getPreviousSession(for: day)
            progressData = workoutManager.getProgressData(for: session, comparedTo: previousSession)
        }
    }

    private func formattedVolume(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }

    private func shortDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m == 0 ? "\(h) \("ч".localized())" : "\(h)\("ч".localized()) \(m)\("м".localized())"
        }
        return "\(mins) \("мин".localized())"
    }

    private func deltaText(_ delta: Int) -> String {
        if delta > 0 { return "+\(delta)% \("от прошлой".localized())" }
        if delta < 0 { return "\(delta)% \("от прошлой".localized())" }
        return "Стабильно".localized()
    }

    private func deltaColor(_ delta: Int) -> Color {
        if delta > 0 { return DesignSystem.Colors.neonGreen }
        if delta < 0 { return .red }
        return .white
    }
}

// MARK: - Progress Summary Card

struct ProgressSummaryCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    let currentSession: WorkoutSession
    let previousSession: WorkoutSession?
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Ваш прогресс".localized())
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                let progressData = workoutManager.getProgressData(
                    for: currentSession,
                    comparedTo: previousSession
                )
                
                ForEach(progressData.indices, id: \.self) { index in
                    let progress = progressData[index]
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ExerciseProgressRow(exerciseProgress: progress)
                        
                        // Highlight improvements
                        if progress.progressState == .improved {
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(
                        progress.progressState == .improved ?
                        DesignSystem.Colors.neonGreen.opacity(0.1) : Color.clear
                    )
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    
                    if index < progressData.count - 1 {
                        Divider()
                            .background(DesignSystem.Colors.secondaryText.opacity(0.2))
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Active Workout Content (Adapter for existing CurrentWorkoutCard logic)

struct ActiveWorkoutContent: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    let workoutDay: WorkoutDay
    let programName: String
    
    @State private var showingAddExercise = false
    
    // Centralized query - one fetch for all cards
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse)
    private var allCompletedSessions: [WorkoutSession]
    
    // Computed active exercise ID
    @State private var manualSelectedId: UUID? = nil

    private var activeExerciseId: UUID? {
        if let manual = manualSelectedId { return manual }
        
        guard let session = workoutManager.currentSession else {
            return workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }.first?.id
        }
        
        let exercises = workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }
        
        for exercise in exercises {
            let completedCount = session.sets.filter { $0.exerciseName == exercise.name }.count
            if completedCount < exercise.plannedSets {
                return exercise.id
            }
        }
        
        return exercises.last?.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            let exercises = workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }
            let activeId = activeExerciseId
            
            ForEach(exercises, id: \.id) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    programName: programName,
                    session: workoutManager.currentSession,
                    workoutType: exercise.resolvedWorkoutType,
                    isActive: exercise.id == activeId,
                    allCompletedSessions: allCompletedSessions,
                    aiRecommendation: getRecommendation(for: exercise),
                    onDelete: { deleteExercise(exercise) }
                )
                .id(exercise.id)
                .onTapGesture {
                    withAnimation {
                        manualSelectedId = exercise.id
                    }
                }
            }
            .id(workoutDay.exercises.count) // Force refresh when exercises count changes
            
            // Add exercise button
            Button(action: { showingAddExercise = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 5)
                    Text("Добавить упражнение".localized())
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .staggeredAppear(index: 8)
            
            // Finish workout button
            if let session = workoutManager.currentSession, !session.sets.isEmpty {
                GradientButton(title: "Закончить тренировку".localized(), icon: "checkmark.circle.fill") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    Task {
                        await workoutManager.finishWorkout()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 15, x: 0, y: 8)
                .staggeredAppear(index: 9)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
        .sheet(isPresented: $showingAddExercise) {
            ExerciseSelectionView { exercise in
                addExercise(exercise)
            }
        }
    }
    
    private func addExercise(_ exercise: LibraryExercise) {
        let newExercise = ExerciseTemplate(
            name: exercise.name,
            plannedSets: 3,
            orderIndex: workoutDay.exercises.count
        )
        
        workoutDay.exercises.append(newExercise)
        modelContext.insert(newExercise)
        
        showingAddExercise = false
    }
    
    private func deleteExercise(_ exercise: ExerciseTemplate) {
        withAnimation {
            if let session = workoutManager.currentSession {
                let setsToRemove = session.sets.filter { $0.exerciseName == exercise.name }
                for set in setsToRemove {
                    session.sets.removeAll { $0.id == set.id }
                    modelContext.delete(set)
                }
            }
            
            workoutDay.exercises.removeAll { $0.id == exercise.id }
            modelContext.delete(exercise)
            
            for (index, ex) in workoutDay.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
                ex.orderIndex = index
            }
            
            try? modelContext.save()
        }
    }
    
    private func getRecommendation(for exercise: ExerciseTemplate) -> String? {
        // Placeholder for AI recommendation
        // In real app, this would come from a service or analysis model
        return nil
    }
}

// MARK: - Bento Helper
struct BentoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
    
    }
}

// MARK: - Stat Bento Card
struct StatBentoCard: View {
    let title: String
    let value: String
    var subValue: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        HeaderBentoCard(color: color.opacity(0.15)) {
            content
        }

    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
                
                Text(title.localizedUppercase)
                    .font(DesignSystem.Typography.sectionHeader())
                    .foregroundColor(color.opacity(0.8))
                    .tracking(1.0)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.monospaced(.title3, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let sub = subValue {
                    Text(sub)
                        .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Missing Helper Components

struct LastWorkoutBento: View {
    let session: WorkoutSession
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                    Text("Последняя тренировка".localized())
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(formatDate(session.date))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Text(session.workoutDayName.localized())
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let cals = session.calories {
                        Label("\(cals) kcal", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if let duration = session.endTime?.timeIntervalSince(session.date) {
                        Label(formatDuration(duration), systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .frame(height: 120)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) \("мин".localized())"
    }
}

// MARK: - View Modifiers

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.1)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}

// MARK: - Workout Summary Stats
struct WorkoutSummaryStats: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. Duration (Blue)
            SummaryStatBox(
                title: "Время".localized().uppercased(),
                value: formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0),
                unit: nil,
                icon: "timer",
                color: .blue
            )
            
            // 2. Calories (Orange)
            SummaryStatBox(
                title: "ккал".localized().uppercased(),
                value: "\(session.calories ?? 0)",
                unit: "ккал".localized(),
                icon: "flame.fill",
                color: .orange
            )
            
            // 3. Heart Rate (Red)
            SummaryStatBox(
                title: "Пульс".localized().uppercased(),
                value: "\(session.averageHeartRate ?? 0)",
                unit: "уд/мин".localized(),
                icon: "heart.fill",
                color: .red
            )
        }
        .frame(height: 100)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = LanguageManager.shared.currentLocale
        formatter.calendar = calendar
        return formatter.string(from: duration) ?? "0 мин"
    }
}

struct SummaryStatBox: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.caption)
                    
                    Text(title)
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(DesignSystem.Typography.title3())
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
