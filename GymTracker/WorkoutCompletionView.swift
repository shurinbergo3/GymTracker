//
//  WorkoutCompletionView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct WorkoutCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    let session: WorkoutSession
    
    @Query(sort: \WorkoutSession.date, order: .forward) private var allHistorySessions: [WorkoutSession]
    
    // Missing State Variables
    @State private var calories: Int = 0
    @State private var isEditingCalories = false
    @State private var heartRate: Int = 0
    @State private var workoutNotes: String = ""
    @State private var progressData: [ExerciseProgress] = []
    
    // Combine history with current session for the chart
    private var chartSessions: [WorkoutSession] {
        var sessions = allHistorySessions.filter { $0.isCompleted }
        // Add current session if not already in the list (it might not be saved/completed yet in DB terms)
        if !sessions.contains(where: { $0.id == session.id }) {
            sessions.append(session)
        }
        return sessions
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        
                        // Header with Activity Rings
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                // Rings as the main visual
                                ActivityRingsView()
                                    .frame(width: 120, height: 120)
                                
                                // Checkmark overlay (Badge style)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .background(Color.black.clipShape(Circle())) // Border effect
                                    .offset(x: 40, y: 40)
                            }
                            .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.3), radius: 20, x: 0, y: 0)
                            
                            Text("Тренировка завершена!")
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // MARK: - Bento Grid Stats
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            
                            // 1. Time (Blue)
                            CompletionBentoCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                        Text("Время")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    Spacer()
                                    Text(formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0))
                                        .font(DesignSystem.Typography.title2())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                }
                            }
                            .frame(height: 110)
                            
                            // 2. Calories (Orange, Interactive)
                            CompletionBentoCard {
                                VStack(alignment: .leading, spacing: 4) {
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
                                            .font(DesignSystem.Typography.title2())
                                            .keyboardType(.numberPad)
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        Text("\(calories > 0 ? "\(calories)" : "--")")
                                            .font(DesignSystem.Typography.title2())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                            .onTapGesture {
                                                if calories == 0 { isEditingCalories = true }
                                            }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 110)
                            
                            // 3. Heart Rate (Red)
                            CompletionBentoCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                        Text("Пульс")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    Spacer()
                                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                                        Text(heartRate > 0 ? "\(heartRate)" : "--")
                                            .font(DesignSystem.Typography.title2())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        Text("уд/мин")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 110)
                            
                            // 4. Records (Green)
                            CompletionBentoCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                        Text("Рекорды")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    Spacer()
                                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                                        Text("\(countImprovements())")
                                            .font(DesignSystem.Typography.title2())
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                        Text("новых")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 110)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                        // Progress Chart (Full Width)
                        WorkoutProgressChart(sessions: chartSessions)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.top, DesignSystem.Spacing.sm)
                        
                        // MARK: - Exercise Breakdown
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("ДЕТАЛИЗАЦИЯ")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            ForEach(progressData, id: \.exerciseName) { item in
                                CompletionBentoCard {
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
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        }
                        
                        // Close Button
                        GradientButton(title: "Закрыть", icon: "checkmark") {
                            completeWorkout()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            setupView()
        }
    }
    
    private func setupView() {
        workoutNotes = session.notes ?? ""
        calories = session.calories ?? 0
        heartRate = session.averageHeartRate ?? 0
        
        // Load comparison data
        if let day = workoutManager.selectedDay {
             let previousSession = workoutManager.getPreviousSession(for: day)
             progressData = workoutManager.getProgressData(for: session, comparedTo: previousSession)
        }
    }
    
    private func countImprovements() -> Int {
        progressData.filter { $0.progressState == .improved }.count
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
    
    private func completeWorkout() {
        session.notes = workoutNotes.isEmpty ? nil : workoutNotes
        session.isCompleted = true
        session.calories = calories
        session.averageHeartRate = heartRate
        
        workoutManager.closeWorkout()
        try? modelContext.save()
        dismiss()
    }
}

// Unified Card Style
fileprivate struct CompletionBentoCard<Content: View>: View {
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
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    let session = WorkoutSession(workoutDayName: "День груди")
    container.mainContext.insert(session)
    let mockManager = WorkoutManager(modelContext: container.mainContext)
    
    return WorkoutCompletionView(session: session)
        .environmentObject(mockManager)
        .modelContainer(container)
}
