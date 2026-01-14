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
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Calendar
                ExpandableCalendarView()
                
                // Program progress banner
                if let activeProgram = workoutManager.activeProgram {
                    WorkoutProgressBanner(
                        programName: activeProgram.name,
                        program: activeProgram
                    )
                }
                
                // Card 1: Plan for Today (Interactive)
                TodaysPlanCard(showingDaySelection: $showingDaySelection)
                    .environmentObject(workoutManager)
                
                // Card 2: Previous Progress
                PreviousProgressCard()
                    .environmentObject(workoutManager)
            }
            .padding(DesignSystem.Spacing.lg)
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
                    // Timer header
                    HStack {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "timer")
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                            Text(formattedTime)
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .monospacedDigit()
                        }
                        
                        Spacer()
                        
                        // Cancel button
                        Button(action: { showingCancelConfirmation = true }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Отменить")
                            }
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(.red)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
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
                // Scroll to top when workout starts
                proxy.scrollTo("top", anchor: .top)
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
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxl) {
                    Spacer().frame(height: DesignSystem.Spacing.xl)
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 120))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.6), radius: 30, x: 0, y: 0)
                    
                    // Title
                    Text("Тренировка завершена!")
                        .font(DesignSystem.Typography.largeTitle())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    // Progress summary
                    if let currentSession = workoutManager.currentSession,
                       let selectedDay = workoutManager.selectedDay {
                        let previousSession = workoutManager.getPreviousSession(for: selectedDay)
                        
                       if previousSession != nil {
                            ProgressSummaryCard(
                                currentSession: currentSession,
                                previousSession: previousSession
                            )
                            .environmentObject(workoutManager)
                        }
                        
                        // Progress graph
                        WorkoutProgressGraph(workoutDayName: selectedDay.name)
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
                        workoutManager.closeWorkout()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    Spacer().frame(height: DesignSystem.Spacing.xxl)
                }
            }
        }
        .onAppear {
            notes = workoutManager.currentSession?.notes ?? ""
        }
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
