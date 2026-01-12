//
//  WorkoutHistoryView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @State private var selectedMonth = Date()
    
    // Только завершенные тренировки
    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Календарь вверху
                    ExpandableCalendarView()
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // График прогресса
                    WorkoutProgressChart(sessions: completedSessions)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Список тренировок
                    if completedSessions.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "figure.strengthtraining.traditional",
                            title: "Нет завершенных тренировок",
                            message: "История ваших тренировок появится здесь",
                            buttonTitle: "Начать тренировку"
                        ) {
                            dismiss()
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(completedSessions, id: \.self) { session in
                                    NavigationLink(destination: WorkoutHistoryDetailView(session: session)) {
                                        WorkoutHistoryCard(session: session)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.bottom, DesignSystem.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("История тренировок")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Workout History Card

struct WorkoutHistoryCard: View {
    let session: WorkoutSession
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: session.date).capitalized
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: session.date)
    }
    
    private var totalSets: Int {
        session.sets.count
    }
    
    private var totalVolume: Double {
        session.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text(session.workoutDayName)
                            .font(DesignSystem.Typography.title3())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(formattedDate)
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                }
                
                Divider()
                    .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Подходы
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("ПОДХОДЫ")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Text("\(totalSets)")
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                    
                    // Объем
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("ОБЪЕМ")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Text(String(format: "%.0f кг", totalVolume))
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Комментарий (если есть)
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("ОТЗЫВ")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Text(notes)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(2)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Workout History Detail View

struct WorkoutHistoryDetailView: View {
    let session: WorkoutSession
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy 'в' HH:mm"
        return formatter.string(from: session.date).capitalized
    }
    
    // Группировка подходов по упражнениям
    private var exerciseGroups: [(name: String, sets: [WorkoutSet])] {
        let grouped = Dictionary(grouping: session.sets.sorted { $0.setNumber < $1.setNumber }, by: { $0.exerciseName })
        return grouped.map { (name: $0.key, sets: $0.value) }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                    // Заголовок с датой
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text(session.workoutDayName)
                            .font(DesignSystem.Typography.title())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(formattedDate)
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Комментарий (если есть)
                    if let notes = session.notes, !notes.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("ОТЗЫВ О ТРЕНИРОВКЕ")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.2)
                                
                                Text(notes)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            .padding(DesignSystem.Spacing.xl)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Упражнения
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        ForEach(exerciseGroups, id: \.name) { group in
                            ExerciseHistoryCard(exerciseName: group.name, sets: group.sets)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
        }
        .navigationTitle("Детали тренировки")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Exercise History Card (for detail view)

struct ExerciseHistoryCard: View {
    let exerciseName: String
    let sets: [WorkoutSet]
    
    private var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Название упражнения
                HStack {
                    Text(exerciseName)
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f кг", totalVolume))
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                }
                
                Divider()
                    .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                
                // Подходы
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Подход \(index + 1)")
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                            
                            Text("\(Int(set.weight)) кг × \(set.reps)")
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
