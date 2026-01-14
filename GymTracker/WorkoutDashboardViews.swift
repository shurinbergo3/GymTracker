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
    
    // Fetch last completed session for "Last Workout" stats
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse)
    private var history: [WorkoutSession]
    
    private var lastSession: WorkoutSession? { history.first }
    
    private var daysSinceLastWorkout: Int {
        guard let lastDate = lastSession?.date else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Calendar
                ExpandableCalendarView()
                
                // MARK: - Last Workout Bento Grid
                if let session = lastSession {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Text("Ваша прошлая тренировка")
                                .font(DesignSystem.Typography.sectionHeader())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                        }
                        
                        // Main Card: Workout Name & Date
                        CardView {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text(session.workoutDayName)
                                        .font(DesignSystem.Typography.title3())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text(formatDate(session.date))
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                            }
                            .padding()
                        }
                        
                        // Stats Row
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Duration
                            StatBentoCard(
                                title: "Время",
                                value: formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0),
                                icon: "clock.fill",
                                color: .blue
                            )
                            
                            // Calories 
                            StatBentoCard(
                                title: "Ккал",
                                value: session.calories != nil ? "\(session.calories!)" : "--",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            // Heart Rate
                            StatBentoCard(
                                title: "Пульс",
                                value: session.averageHeartRate != nil ? "\(session.averageHeartRate!)" : "--",
                                subValue: "уд/мин",
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                        .frame(height: 100)
                        
                        // Days Inactive Label
                        if daysSinceLastWorkout > 0 {
                            HStack {
                                Spacer()
                                Text("Вы не тренировались \(daysSinceLastWorkout) \(daysString(daysSinceLastWorkout))")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .italic()
                                Spacer()
                            }
                            .padding(.top, DesignSystem.Spacing.xs)
                        }
                    }
                } else {
                    // Empty State if no history
                    CardView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "figure.run")
                                .font(.largeTitle)
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                            Text("Добро пожаловать!")
                                .font(DesignSystem.Typography.headline())
                            Text("Ваша статистика появится здесь после первой тренировки")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(DesignSystem.Spacing.xl)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // MARK: - Plan for Today & Start Button
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Day Selection Header
                    HStack {
                        if let selectedDay = workoutManager.selectedDay {
                            VStack(alignment: .leading) {
                                Text("ПЛАН НА СЕГОДНЯ")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.2)
                                
                                Text(selectedDay.name)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        } else {
                            Text("Выберите программу")
                                .font(DesignSystem.Typography.title3())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Button(action: { showingDaySelection = true }) {
                            Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    
                    // Large Start Button
                    Button(action: { workoutManager.startWorkout() }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("Начать тренировку")
                                .font(DesignSystem.Typography.headline())
                        }
                        .foregroundColor(DesignSystem.Colors.background) // Black text on Green
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20) // Taller button
                        .background(
                            LinearGradient(
                                colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.CornerRadius.large)
                        .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(workoutManager.selectedDay == nil)
                    .opacity(workoutManager.selectedDay == nil ? 0.5 : 1)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground) // Background for the "Control Center"
                .cornerRadius(DesignSystem.CornerRadius.large)
            }
            .padding(DesignSystem.Spacing.lg)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
    
    private func daysString(_ days: Int) -> String {
        // Simple pluralization for "days"
        // 1 день, 2-4 дня, 5+ дней
        let lastDigit = days % 10
        let lastTwoDigits = days % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "дней"
        }
        
        switch lastDigit {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
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
    @State private var elapsedTime: TimeInterval = 0
    @State private var showingCancelConfirmation = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Active Workout Bento Header
                    ActiveWorkoutHeader(
                        elapsedTime: elapsedTime,
                        showingCancelConfirmation: $showingCancelConfirmation
                    )
                    .environmentObject(workoutManager)
                    .id("top")
                    
                    // Progress banner
                    if let activeProgram = workoutManager.activeProgram {
                        WorkoutProgressBanner(
                            programName: activeProgram.name,
                            program: activeProgram
                        )
                    }
                    
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
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .onAppear {
                // Scroll to top when workout starts (with slight delay for layout)
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
                // Reset timer
                elapsedTime = 0
            }
            .onReceive(timer) { _ in
                elapsedTime += 1
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
