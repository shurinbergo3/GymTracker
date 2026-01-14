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
    
    @State private var calories: Int = 0
    @State private var heartRate: Int = 0
    @State private var workoutNotes: String = ""
    @State private var isEditingCalories = false
    @State private var progressData: [ExerciseProgress] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        
                        // Header
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 20, x: 0, y: 0)
                            
                            Text("Тренировка завершена!")
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // MARK: - Bento Grid Stats
                        VStack(spacing: DesignSystem.Spacing.md) {
                            HStack(spacing: DesignSystem.Spacing.md) {
                                // Time (Blue)
                                StatBentoCard(
                                    title: "Время",
                                    value: formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0),
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
                            WorkoutProgressChart(sessions: [session])
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

struct StatBentoCard: View {
    let title: String
    let value: String
    var subValue: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if let sub = subValue {
                        Text(sub)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding()
        }
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
