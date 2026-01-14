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
    let session: WorkoutSession
    
    @State private var calories: Int = 0
    @State private var workoutNotes: String = ""
    @State private var isEditingCalories = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                // Большая иконка успеха
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(DesignSystem.Colors.neonGreen)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 20, x: 0, y: 0)
                
                // Заголовок
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Тренировка завершена!")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Отличная работа! Поделитесь впечатлениями")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Calories Row
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Калории:")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    if isEditingCalories {
                        TextField("kcal", value: $calories, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Button("OK") { isEditingCalories = false }
                    } else {
                        Text("\(calories) kcal")
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .onTapGesture {
                                if calories == 0 { isEditingCalories = true }
                            }
                        if calories == 0 {
                            Button(action: { isEditingCalories = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                        }
                    }
                }
                .font(DesignSystem.Typography.body())
                .padding()
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)

                // Поле для заметок (необязательное)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("ОТЗЫВ О ТРЕНИРОВКЕ (необязательно)")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.2)
                    
                    TextEditor(text: $workoutNotes)
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
                
                Spacer()
                
                // Кнопка завершения - большая и яркая
                GradientButton(title: "Закрыть", icon: "checkmark.circle.fill") {
                    completeWorkout()
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            workoutNotes = session.notes ?? ""
            calories = session.calories ?? 0
        }
    }
    
    
    private func completeWorkout() {
        session.notes = workoutNotes.isEmpty ? nil : workoutNotes
        session.isCompleted = true
        session.calories = calories // Update session with final calories (fetched or edited)
        
        // Save to Firestore
        let workoutDTO = Workout(from: session)
        FirestoreManager.shared.save(workout: workoutDTO)
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, configurations: config)
    let session = WorkoutSession(workoutDayName: "День груди")
    container.mainContext.insert(session)
    
    return WorkoutCompletionView(session: session)
        .modelContainer(container)
}
