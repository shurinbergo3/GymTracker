//
//  DaySelectionSheet.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct DaySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutManager: WorkoutManager
    let program: Program
    @Binding var selectedDay: WorkoutDay?
    
    @Query private var allSessions: [WorkoutSession]
    
    private func lastPerformed(for day: WorkoutDay) -> Date? {
        allSessions
            .filter { $0.workoutDayName == day.name && $0.isCompleted }
            .sorted { $0.date > $1.date }
            .first?.date
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(program.days.sorted { $0.orderIndex < $1.orderIndex }, id: \.self) { day in
                            DaySelectionCard(
                                day: day,
                                isSelected: selectedDay == day,
                                lastPerformed: lastPerformed(for: day)
                            ) {
                                selectedDay = day
                                workoutManager.selectDay(day)
                                dismiss()
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Выбор тренировки".localized())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }
}

// MARK: - Day Selection Card

struct DaySelectionCard: View {
    let day: WorkoutDay
    let isSelected: Bool
    let lastPerformed: Date?
    let onSelect: () -> Void
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        Button(action: onSelect) {
            CardView {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    // Day index indicator
                    ZStack {
                        Circle()
                            .fill(isSelected ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.cardBackground)
                            .frame(width: 44, height: 44)
                        
                        Text("\(day.orderIndex + 1)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(isSelected ? .black : DesignSystem.Colors.primaryText)
                    }
                    
                    // Day info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(day.name.localized())
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text(String(format: "%d упражнений".localized(), day.exercises.count))
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            if let lastDate = lastPerformed {
                                Text("•")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text(formatDate(lastDate))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    makeDaySelectionSheetPreview()
}

@MainActor
private func makeDaySelectionSheetPreview() -> some View {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Program.self, WorkoutDay.self, configurations: config)
    
    let program = Program(name: "PPL", isActive: true)
    let day1 = WorkoutDay(name: "Push", orderIndex: 0)
    let day2 = WorkoutDay(name: "Pull", orderIndex: 1)
    let day3 = WorkoutDay(name: "Legs", orderIndex: 2)
    
    program.days = [day1, day2, day3]
    container.mainContext.insert(program)
    
    return DaySelectionSheet(program: program, selectedDay: .constant(day1 as WorkoutDay?))
        .modelContainer(container)
        .environmentObject(WorkoutManager(
            modelContext: container.mainContext,
            healthProvider: HealthManager.shared,
            activityProvider: LiveActivityManager.shared
        ))
}
