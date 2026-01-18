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

// MARK: - Sleep Analysis UI

struct SleepCard: View {
    @State private var sleepData: [SleepData] = []
    @State private var totalSleep: TimeInterval = 0
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            BentoCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(Color.purple)
                        Text("Сон")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    
                    if sleepData.isEmpty {
                        Text("Нет данных")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatDuration(totalSleep))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("всего")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .padding(.bottom, 4)
                        }
                        
                        // Mini Sleep Graph Bar
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                ForEach(sleepData.sorted(by: { $0.startDate < $1.startDate })) { segment in
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
                let data = await HealthManager.shared.fetchSleepData()
                await MainActor.run {
                    self.sleepData = data
                    
                    // Smart calculation: Merge overlapping intervals
                    let filteredSegments = data.filter { $0.type != .inBed }
                    let sortedSegments = filteredSegments.sorted { $0.startDate < $1.startDate }
                    
                    var totalDuration: TimeInterval = 0
                    var currentInterval: (start: Date, end: Date)?
                    
                    for segment in sortedSegments {
                        if let current = currentInterval {
                            if segment.startDate < current.end {
                                // Overlap: Extend end if needed
                                if segment.endDate > current.end {
                                    currentInterval?.end = segment.endDate
                                }
                            } else {
                                // No overlap: Commit current and start new
                                totalDuration += current.end.timeIntervalSince(current.start)
                                currentInterval = (segment.startDate, segment.endDate)
                            }
                        } else {
                            currentInterval = (segment.startDate, segment.endDate)
                        }
                    }
                    
                    // Commit last interval
                    if let current = currentInterval {
                        totalDuration += current.end.timeIntervalSince(current.start)
                    }
                    
                    self.totalSleep = totalDuration
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)ч \(minutes)м"
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
                    Text("ПЛАН НА СЕГОДНЯ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    
                    if let day = workoutManager.selectedDay {
                        Text(day.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    } else {
                        Text("Отдых")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                
                Spacer()
                
                // Day Selector
                Button(action: { showingDaySelection = true }) {
                    Image(systemName: "list.dash")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Start Button
            Button(action: { workoutManager.startWorkout() }) {
                HStack {
                    Spacer()
                    Text(workoutManager.selectedDay == nil ? "Выбрать программу" : "НАЧАТЬ ТРЕНИРОВКУ")
                        .font(.headline)
                        .fontWeight(.bold)
                    Image(systemName: "play.fill")
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.accent], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.black)
            }
            .disabled(workoutManager.selectedDay == nil)
            .opacity(workoutManager.selectedDay == nil ? 0.6 : 1)
        }
    }
    
    // MARK: - Active State (Workout In Progress)
    private var activeWorkoutContent: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ТРЕНИРОВКА")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                        
                        if let day = workoutManager.selectedDay {
                            Text(day.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Pulsing indicator
                    Circle()
                        .fill(DesignSystem.Colors.neonGreen)
                        .frame(width: 12, height: 12)
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
                        Label("Время", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(formatElapsedTime(context.date))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // Exercises Progress
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("Прогресс", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(progressText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                    }
                    
                    // Calories
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("Ккал", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text("\(workoutManager.currentActiveCalories)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.accent], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * progressPercentage, height: 6)
                    }
                }
                .frame(height: 6)
                
                // Tap to View Button
                Button(action: onOpenWorkout) {
                    HStack {
                        Spacer()
                        Text("ОТКРЫТЬ ТРЕНИРОВКУ")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Stats
                    HStack(spacing: 20) {
                        SleepStatBox(title: "Всего сна", value: formatDuration(totalSleep), color: .white)
                        SleepStatBox(title: "В кровати", value: formatDuration(totalInBed), color: .gray)
                    }
                    .padding(.top)
                    
                    // Main Graph
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Фазы сна")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Chart {
                            ForEach(sleepData) { datum in
                                BarMark(
                                    x: .value("Time", datum.startDate ..< datum.endDate),
                                    y: .value("Stage", datum.label)
                                )
                                .foregroundStyle(datum.color)
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
                    
                    // Legend / Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Детализация")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.bottom, 4)
                        
                        SleepLegendRow(color: .purple, label: "Глубокий сон", duration: duration(for: .asleepDeep))
                        Divider().background(Color.gray.opacity(0.3))
                        SleepLegendRow(color: .blue, label: "Базовый сон", duration: duration(for: .asleepCore))
                        Divider().background(Color.gray.opacity(0.3))
                        SleepLegendRow(color: .cyan, label: "Быстрый сон (REM)", duration: duration(for: .asleepREM))
                        Divider().background(Color.gray.opacity(0.3))
                        SleepLegendRow(color: .orange, label: "Бодрствование", duration: duration(for: .awake))
                    }
                    .padding()
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(16)
                }
                .padding()
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Сон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                }
            }
        }
    }
    
    // Helpers
    private var totalSleep: TimeInterval {
        sleepData.filter { $0.type == .asleepCore || $0.type == .asleepDeep || $0.type == .asleepREM || $0.type == .asleepUnspecified }.reduce(0) { $0 + $1.duration }
    }
    
    private var totalInBed: TimeInterval {
        sleepData.filter { $0.type == .inBed }.reduce(0) { $0 + $1.duration }
    }
    
    private func duration(for type: HKCategoryValueSleepAnalysis) -> TimeInterval {
        sleepData.filter { $0.type == type }.reduce(0) { $0 + $1.duration }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)ч \(minutes)м"
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
        return "\(hours)ч \(minutes)м"
    }
}

// MARK: - Dashboard View (Idle State)

struct DashboardView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingDaySelection = false
    
    // Fetch recent history
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse)
    private var history: [WorkoutSession]
    
    private var recentHistory: [WorkoutSession] {
        Array(history.prefix(1))
    }
    
    private var daysSinceLastWorkout: Int {
        guard let lastDate = history.first?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }
    

    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Calendar
                ExpandableCalendarView()
                
                // MARK: - Top Stats Row (Neon Style)
                VStack(spacing: DesignSystem.Spacing.lg) {
                    
                    // Row 1: Activity Rings (Standardized)
                    ActivityRingsCard()
                    
                    // Row 2: Growth Indicator (Replaces Progress)
                    // Row 2: Growth Indicator
                    WorkoutProgressChart(sessions: history)
                    

                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Row 2: Today's Plan / Active Workout Card
                TodayWorkoutCard(
                    workoutManager: workoutManager,
                    showingDaySelection: $showingDaySelection,
                    onOpenWorkout: {
                        // Scroll to active workout
                        if workoutManager.workoutState == .active {
                            // The active workout view will be shown via the main dashboard logic
                        }
                    }
                )
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // History Section (Cards List)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("ПРОШЛАЯ ТРЕНИРОВКА")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.2)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    if recentHistory.isEmpty {
                        Text("История пуста")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    } else {
                        ForEach(recentHistory, id: \.self) { session in
                            HistoryCardView(session: session)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                }
                
                // AI Coach Placeholder
                AICoachPlaceholderView()
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer().frame(height: 80) // Bottom padding
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
        formatter.locale = Locale(identifier: "ru_RU")
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
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Day Name (Big)
                    Text(session.workoutDayName)
                        .font(.headline)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    
                    // Program Name (Small)
                    if let programName = session.programName {
                        Text(programName)
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
                        Text("\(calories) ккал")
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
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            WorkoutSessionDetailView(session: session)
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
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

// MARK: - AI Coach Placeholder
struct AICoachPlaceholderView: View {
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(red: 0.1, green: 0, blue: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.purple.opacity(0.2), radius: 10)
            
            // Content
            HStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Тренер")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Персональные советы и анализ прогресса")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
            }
            .padding(24)
            .opacity(0.3) // Dimmed
            
            // Overlay "In Development"
            ZStack {
                Color.black.opacity(0.6)
                    .cornerRadius(20)
                
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(.gray)
                    
                    Text("В РАЗРАБОТКЕ")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(2)
                }
            }
        }
        .frame(height: 120)
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
                Text("План на сегодня")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                // Day selector
                if let selectedDay = workoutManager.selectedDay {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(selectedDay.name)
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("\(selectedDay.exercises.count) упражнений")
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
                    Text("Выберите тренировку")
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Start button
                GradientButton(title: "Начать тренировку", icon: "play.fill") {
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
                Text("Прошлые успехи")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                let progressData = workoutManager.getPreviewProgressData()
                
                if progressData.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                        
                        Text("Нет данных")
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("Выполните первую тренировку, чтобы отслеживать прогресс")
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
                    ActiveWorkoutHeader(
                        showingCancelConfirmation: $showingCancelConfirmation
                    )
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
                "Отменить тренировку?",
                isPresented: $showingCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Отменить тренировку", role: .destructive) {
                    workoutManager.cancelWorkout()
                }
                Button("Продолжить", role: .cancel) { }
            } message: {
                Text("Данные текущей тренировки не будут сохранены.")
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
                    Text("Тренировка завершена!")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    if let currentSession = workoutManager.currentSession {
                        
                        // MARK: - Bento Grid Stats
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            
                            // 1. Activity Rings (Top) - Standardized
                            ActivityRingsCard()
                            
                            // 2. Stats Grid (Equal Height)
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Time (Blue)
                                StatBentoCard(
                                    title: "Время",
                                    value: formatDuration(currentSession.endTime?.timeIntervalSince(currentSession.date) ?? 0),
                                    icon: "clock.fill",
                                    color: .blue
                                )
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                
                                // Calories (Orange, Interactive)
                                CardView {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                            Text("Ккал")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        if isEditingCalories {
                                            TextField("0", value: $calories, format: .number)
                                                .keyboardType(.numberPad)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                        } else {
                                            Text("\(calories > 0 ? "\(calories)" : "--")")
                                                .font(DesignSystem.Typography.title2())
                                                .foregroundColor(DesignSystem.Colors.primaryText)
                                                .onTapGesture {
                                                    if calories == 0 { isEditingCalories = true }
                                                }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Heart Rate (Red)
                                StatBentoCard(
                                    title: "Пульс",
                                    value: heartRate > 0 ? "\(heartRate)" : "--",
                                    subValue: "уд/мин",
                                    icon: "heart.fill",
                                    color: .red
                                )
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                
                                // Records / Best (Green)
                                StatBentoCard(
                                    title: "Рекорды",
                                    value: "\(countImprovements())",
                                    subValue: "новых",
                                    icon: "trophy.fill",
                                    color: DesignSystem.Colors.neonGreen
                                )
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Progress Chart (Full Width)
                            WorkoutProgressChart(sessions: [currentSession])
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // MARK: - Exercise Breakdown
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("ДЕТАЛИЗАЦИЯ")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                            ForEach(progressData, id: \.exerciseName) { item in
                                CardView {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.exerciseName)
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
                        Text("Отзыв о тренировке (необязательно)")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(DesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                            )
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Close button
                    GradientButton(title: "Закрыть и сохранить", icon: "checkmark.circle.fill") {
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
                if let day = workoutManager.selectedDay {
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
        calendar.locale = Locale(identifier: "ru_RU")
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
                Text("Ваш прогресс")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            // Exercises list - use exercises array directly with count in id to handle lazy loading
            let exercises = workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }
            
            ForEach(exercises, id: \.id) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    programName: programName,
                    session: workoutManager.currentSession,
                    workoutType: exercise.type,
                    allCompletedSessions: allCompletedSessions
                )
                .id(exercise.id)
            }
            .id(workoutDay.exercises.count) // Force refresh when exercises count changes
            
            // Add exercise button
            Button(action: { showingAddExercise = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Добавить упражнение")
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.large)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Finish workout button
            if let session = workoutManager.currentSession, !session.sets.isEmpty {
                GradientButton(title: "Закончить тренировку", icon: "checkmark.circle.fill") {
                    workoutManager.finishWorkout()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
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
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color.opacity(0.8))
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let sub = subValue {
                    Text(sub)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}
