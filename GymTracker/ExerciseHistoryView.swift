//
//  ExerciseHistoryView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    let programName: String
    
    @Query private var allSessions: [WorkoutSession]
    
    // Фильтруем сессии с подходами для этого упражнения
    private var exerciseSessions: [(date: Date, sets: [WorkoutSet])] {
        let sessionsWithExercise = allSessions.filter { session in
            session.sets.contains { $0.exerciseName == exerciseName }
        }
        
        // Группируем подходы по датам
        let grouped = Dictionary(grouping: sessionsWithExercise) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        
        // Сортируем по дате (новые сверху)
        return grouped.map { date, sessions in
            let sets = sessions.flatMap { $0.sets }
                .filter { $0.exerciseName == exerciseName }
                .sorted { $0.setNumber < $1.setNumber }
            return (date: date, sets: sets)
        }
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if exerciseSessions.isEmpty {
                    ContentUnavailableView {
                        Label("Нет истории", systemImage: "clock.arrow.circlepath")
                            .font(DesignSystem.Typography.body())
                    } description: {
                        Text("Вы еще не выполняли это упражнение")
                            .font(DesignSystem.Typography.callout())
                    }
                } else {
                    ForEach(exerciseSessions, id: \.date) { sessionData in
                        Section {
                            ForEach(sessionData.sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.self) { set in
                                HStack {
                                    Text("Подход \(set.setNumber)")
                                        .font(DesignSystem.Typography.callout())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(set.weight)) кг × \(set.reps)")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                }
                            }
                        } header: {
                            Text(formatDate(sessionData.date))
                                .font(DesignSystem.Typography.headline())
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if Calendar.current.isDateInToday(date) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Вчера"
        } else {
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ExerciseHistoryView(
        exerciseName: "Жим штанги лежа",
        programName: "Программа на силу"
    )
    .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
