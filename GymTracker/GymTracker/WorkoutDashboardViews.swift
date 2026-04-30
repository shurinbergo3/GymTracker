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

struct SleepCard: View {
    @State private var sleepData: [SleepData] = []
    @State private var sortedSleepData: [SleepData] = [] // Кэш отсортированных данных, чтобы не пересчитывать в body
    @State private var totalSleep: TimeInterval = 0
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            BentoCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(Color.purple)
                        Text("sleep_title".localized())
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    if sleepData.isEmpty {
                        Text("no_data".localized())
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatDuration(totalSleep))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("sleep_total_label".localized())
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.bottom, 4)
                        }
                        
                        // Mini Sleep Graph Bar
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                ForEach(sortedSleepData) { segment in
                                    if segment.type != .inBed { // Hide "In Bed" for cleaner graph
                                        Rectangle()
                                            .fill(segment.color)
                                            .frame(width: max(1, geo.size.width * (segment.duration / max(1, totalSleep))))
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .frame(height: 120) // Adjust height as needed
        .sheet(isPresented: $showingDetail) {
            SleepDetailView(sleepData: sleepData)
        }
        .task {
            // Fetch logic
            if HealthManager.shared.isAuthorized {
                // Use SleepService for fetching (SRP)
                let data = await SleepService.shared.fetchSleepData()
                await MainActor.run {
                    self.sleepData = data
                    // Сортируем один раз и кэшируем — раньше делалось на каждый рендер ForEach
                    self.sortedSleepData = data.sorted { $0.startDate < $1.startDate }

                    // Use SleepService logic
                    let filteredSegments = data.filter { $0.type != .inBed }
                    let sortedSegments = filteredSegments.sorted { $0.startDate < $1.startDate }

                    self.totalSleep = SleepService.calculateTotalDuration(from: sortedSegments)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)\("ч".localized()) \(minutes)\("м".localized())"
    }
}

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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading) {
                    Text("План на сегодня".localized().localizedUppercase)
                        .font(DesignSystem.Typography.sectionHeader())
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .tracking(1.2)
                    
                    if let day = workoutManager.selectedDay {
                        Text(day.name.localized())
                            .font(DesignSystem.Typography.title2())
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                    } else {
                        Text("rest_day_title".localized())
                            .font(DesignSystem.Typography.title2())
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                    }
                }
                
                Spacer()
                
                // Day Selector
                Button(action: { showingDaySelection = true }) {
                    Image(systemName: "list.dash")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.3), radius: 10)
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Start Button
            Button(action: { workoutManager.startWorkout() }) {
                HStack {
                    Spacer()
                    Text(workoutManager.selectedDay == nil ? "select_program_button".localized() : "start_workout_button".localized())
                        .font(DesignSystem.Typography.headline())
                        .fontWeight(.bold)
                    Image(systemName: "play.fill")
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(colors: [DesignSystem.Colors.neonGreen, Color(red: 0.6, green: 0.9, blue: 0.15)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                .foregroundStyle(.black)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 15, x: 0, y: 8)
            }
            .disabled(workoutManager.selectedDay == nil)
            .opacity(workoutManager.selectedDay == nil ? 0.6 : 1)
            .accessibilityIdentifier("btn_start_workout")
        }
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
        
        let totalSets = day.exercises.reduce(0) { $0 + $1.plannedSets }
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
    @Environment(\.modelContext) private var modelContext
    
    // CRITICAL FIX: Limit query to prevent freeze with large datasets
    // Only fetch last 100 workouts instead of ALL workouts
    @State private var history: [WorkoutSession] = []
    
    private var recentHistory: [WorkoutSession] {
        Array(history.prefix(1))
    }
    
    private var daysSinceLastWorkout: Int {
        guard let lastDate = history.first?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }
    

    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Calendar (Hero Section)
                ExpandableCalendarView()
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Activity Rings (Hero Health Section)
                ActivityRingsCard()
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Full Width Chart (Show only if data exists)
                if !history.isEmpty {
                    WorkoutProgressChart(sessions: history)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // MARK: - Today's Plan (Action Hero Card)
                TodayWorkoutCard(
                    workoutManager: workoutManager,
                    showingDaySelection: $showingDaySelection,
                    onOpenWorkout: { }
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
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
            // Load limited history asynchronously to prevent freeze
            var descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.isCompleted == true },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            // CRITICAL: Limit to 100 most recent to prevent freeze with thousands of workouts
            descriptor.fetchLimit = 100
            
            if let fetchedHistory = try? modelContext.fetch(descriptor) {
                await MainActor.run {
                    self.history = fetchedHistory
                }
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
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
    
    // Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Active Workout Bento Header
                    ActiveWorkoutHeader()
                        .environmentObject(workoutManager)
                        .id("top")
                    
                    // Current workout card
                    if let selectedDay = workoutManager.selectedDay,
                       let programName = workoutManager.activeProgram?.name {
                        ActiveWorkoutContent(
                            workoutDay: selectedDay,
                            programName: programName
                        )
                        .environmentObject(workoutManager)
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
                    Button(action: { showingCancelConfirmation = true }) {
                        ZStack {
                            // Outer dark circle border
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 40, height: 40)
                            
                            // Inner bright red circle
                            Circle()
                                .fill(Color(red: 1.0, green: 0.27, blue: 0.23))
                                .frame(width: 34, height: 34)
                            
                            // White X icon
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color(red: 1.0, green: 0.27, blue: 0.23).opacity(0.5), radius: 8, x: 0, y: 2)
                    }
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
    @State private var isEditingCalories = false
    @State private var progressData: [ExerciseProgress] = []
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer().frame(height: DesignSystem.Spacing.xl)
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80)) // Reduced size to match CompletionView
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 20, x: 0, y: 0)
                    
                    // Title
                    Text("Тренировка завершена!".localized())
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    if let currentSession = workoutManager.currentSession {
                        // MARK: - Bento Grid Stats
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            
                            // 1. Stats Summary (Top)
                            WorkoutSummaryStats(session: currentSession)
                            // Removed glassModifier, check inside component or earlier fix
                            
                            // 2. Records & Progression
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Records / Best (Green) -> Full Width now since others are gone
                                StatBentoCard(
                                    title: "Рекорды".localized(),
                                    value: "\(countImprovements())",
                                    subValue: "новых".localized(),
                                    icon: "trophy.fill",
                                    color: DesignSystem.Colors.neonGreen
                                )
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Progress Chart (Full Width)
                            WorkoutProgressChart(sessions: [currentSession])
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // MARK: - Exercise Breakdown
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("ДЕТАЛИЗАЦИЯ".localized())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                            ForEach(progressData, id: \.exerciseName) { item in
                                CardView {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.exerciseName.localized())
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                            
                                            Text(item.currentStats)
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        if item.progressState != .same && item.progressState != .new {
                                            HStack(spacing: 6) {
                                                Image(systemName: item.progressState.icon)
                                                    .font(.headline)
                                                    .foregroundColor(item.progressState.color)
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(item.progressState.color.opacity(0.15))
                                            .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        }
                    }
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: 6) {
                            Text("комментарий о тренировке".localized().uppercased())
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.neonGreen.opacity(0.8))
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Расскажите как прошла ваша тренировка".localized())
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                                    .padding(.top, 12)
                                    .padding(.leading, 12)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding(4)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Close button
                    GradientButton(title: "Закрыть и сохранить".localized(), icon: "checkmark.circle.fill") {
                        if !notes.isEmpty {
                            workoutManager.currentSession?.notes = notes
                        }
                        workoutManager.currentSession?.calories = calories
                        workoutManager.currentSession?.averageHeartRate = heartRate
                        workoutManager.closeWorkout()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    Spacer().frame(height: DesignSystem.Spacing.xxl)
                }
            }
        }
        .onAppear {
            if let session = workoutManager.currentSession {
                notes = session.notes ?? ""
                calories = session.calories ?? 0
                heartRate = session.averageHeartRate ?? 0
                
                // Compare with previous session logic
                // Fix: selectedDay might have already advanced to the next day.
                // We need to find the day that corresponds to the COMPLETED session.
                if let program = workoutManager.activeProgram,
                   let day = program.days.first(where: { $0.name == session.workoutDayName }) {
                     let previousSession = workoutManager.getPreviousSession(for: day)
                     progressData = workoutManager.getProgressData(for: session, comparedTo: previousSession)
                } else if let day = workoutManager.selectedDay, day.name == session.workoutDayName {
                    // Fallback to selectedDay if names match (unlikely if advanced)
                    let previousSession = workoutManager.getPreviousSession(for: day)
                    progressData = workoutManager.getProgressData(for: session, comparedTo: previousSession)
                }
            }
        }
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
    
    private func countImprovements() -> Int {
        progressData.filter { $0.progressState == .improved }.count
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
