//
//  WorkoutDashboardViews.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Dashboard View (Idle State)

struct DashboardView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingDaySelection = false
    
    // Fetch recent history
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse)
    private var history: [WorkoutSession]
    
    private var recentHistory: [WorkoutSession] {
        Array(history.prefix(3))
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
                HStack(spacing: DesignSystem.Spacing.lg) {
                    
                    // Row 1 Left: Activity (Neon Ring)
                    PremiumBentoCard {
                         VStack(alignment: .leading) {
                             HStack {
                                 Image(systemName: "flame.fill")
                                     .foregroundStyle(DesignSystem.Colors.neonGreen)
                                 Text("Активность")
                                     .font(.headline)
                                     .foregroundStyle(.white)
                             }
                             
                             Spacer()
                             
                             // Neon Ring + Steps
                             HStack {
                                 Spacer()
                                 ZStack {
                                     // Background Ring
                                     Circle()
                                         .stroke(Color.white.opacity(0.1), lineWidth: 8)
                                         .frame(width: 80, height: 80)
                                     
                                     // Progress Ring (Neon)
                                     Circle()
                                         .trim(from: 0, to: 0.75) // 75% progress placeholder
                                         .stroke(
                                             DesignSystem.Colors.neonGreen,
                                             style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                         )
                                         .rotationEffect(.degrees(-90))
                                         .frame(width: 80, height: 80)
                                         .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 10)
                                     
                                     // Inner Icon/Text
                                     VStack(spacing: 2) {
                                         Image(systemName: "figure.walk")
                                             .font(.caption2)
                                             .foregroundStyle(DesignSystem.Colors.neonGreen)
                                         Text("8,542") // Placeholder
                                             .font(.system(size: 14, weight: .bold))
                                             .foregroundStyle(.white)
                                     }
                                 }
                                 Spacer()
                             }
                             
                             Spacer()
                             
                             Text("8,542 шагов")
                                 .font(.caption)
                                 .foregroundStyle(.gray)
                                 .frame(maxWidth: .infinity, alignment: .center)
                         }
                    }
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    
                    // Row 1 Right: Progress (Sparkline)
                    PremiumBentoCard {
                         VStack(alignment: .leading, spacing: 12) {
                             HStack {
                                 Image(systemName: "chart.xyaxis.line")
                                     .foregroundStyle(DesignSystem.Colors.neonGreen)
                                 Text("Прогресс")
                                     .font(.headline)
                                     .foregroundStyle(.white)
                             }
                             
                             Spacer()
                             
                             // Sparkline
                             SparklineGraph(data: [10, 12, 8, 14, 15, 12, 18, 20]) // Mock trend
                                 .stroke(
                                     LinearGradient(colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.neonGreen.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                                     style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                 )
                                 .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.3), radius: 4)
                                 .frame(height: 50)
                             
                             Spacer()
                             
                             HStack {
                                 Text("\(history.count)")
                                     .font(.title2)
                                     .fontWeight(.bold)
                                     .foregroundStyle(.white)
                                 Text("Тренировок")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                             }
                         }
                    }
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Row 2: Today's Plan (Full Width)
                BentoCard {
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
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // History Section (Cards List)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("НЕДАВНИЕ ТРЕНИРОВКИ")
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutDayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            if let calories = session.calories {
                Text("\(calories) ккал")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.neonGreen)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
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
                        VStack(spacing: DesignSystem.Spacing.md) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Time (Blue)
                                StatBentoCard(
                                    title: "Время",
                                    value: formatDuration(currentSession.endTime?.timeIntervalSince(currentSession.date) ?? 0),
                                    icon: "clock.fill",
                                    color: .blue
                                )
                                
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
                                }
                            }
                            .frame(height: 120)
                            
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Heart Rate (Red)
                                StatBentoCard(
                                    title: "Пульс",
                                    value: heartRate > 0 ? "\(heartRate)" : "--",
                                    subValue: "уд/мин",
                                    icon: "heart.fill",
                                    color: .red
                                )
                                
                                // Records / Best (Green)
                                StatBentoCard(
                                    title: "Рекорды",
                                    value: "\(countImprovements())",
                                    subValue: "новых",
                                    icon: "trophy.fill",
                                    color: DesignSystem.Colors.neonGreen
                                )
                            }
                            .frame(height: 120)
                            
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            // Exercises list
            ForEach(workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }, id: \.self) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    programName: programName,
                    session: workoutManager.currentSession,
                    workoutType: workoutDay.workoutType
                )
                .id(exercise.id)
            }
            
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
