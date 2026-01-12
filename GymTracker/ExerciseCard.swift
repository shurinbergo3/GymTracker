//
//  ExerciseCard.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Combine

struct ExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: ExerciseTemplate
    let programName: String
    let session: WorkoutSession?
    let workoutType: WorkoutType // NEW: Тип тренировки
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var duration: String = "" // Для круговой и кардио
    @State private var rounds: String = "" // Для круговой
    @State private var showingInput: Bool = false
    @State private var elapsedTime: TimeInterval = 0 // Таймер
    @State private var timerRunning: Bool = false
    @State private var showingReplacement = false // Для замены упражнения
    @State private var showingComment = false // Для комментария
    @State private var exerciseComment: String = "" // Комментарий к упражнению
    @State private var showingWorkoutTypeChange = false // Для смены типа тренировки
    
    @Query private var allSessions: [WorkoutSession]
    
    private var completedSets: [WorkoutSet] {
        guard let session = session else { return [] }
        return session.sets
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.setNumber < $1.setNumber }
    }
    
    private var previousSets: [WorkoutSet] {
        let previousSessions = allSessions
            .filter { $0.isCompleted && $0.workoutDayName == session?.workoutDayName && $0 != session }
            .sorted { $0.date > $1.date }
        
        guard let prevSession = previousSessions.first else { return [] }
        
        return prevSession.sets
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.setNumber < $1.setNumber }
    }
    
    private var currentSetNumber: Int {
        completedSets.count + 1
    }
    
    private var isExtra: Bool {
        currentSetNumber > exercise.plannedSets
    }
    
    private var canSave: Bool {
        switch workoutType {
        case .strength:
            return !weight.isEmpty && !reps.isEmpty
        case .circuit:
            return !rounds.isEmpty && !duration.isEmpty
        case .cardio:
            return !duration.isEmpty
        }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Exercise Name with Info and Replace Buttons
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(exercise.name)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    ExerciseInfoButton(exerciseName: exercise.name)
                    
                    Spacer()
                    
                    // Replace Button
                    Menu {
                        Button(action: { showingReplacement = true }) {
                            Label("Заменить упражнение", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(action: { showingWorkoutTypeChange = true }) {
                            Label("Изменить тип упражнения", systemImage: "slider.horizontal.3")
                        }
                        
                        Button(action: { showingComment = true }) {
                            Label("Комментарий", systemImage: "text.bubble")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .menuStyle(.button)
                    .menuIndicator(.hidden)
                    
                    Text("\(exercise.plannedSets) подходов")
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Previous Results
                if !previousSets.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("ПРОШЛЫЙ РЕЗУЛЬТАТ")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        ForEach(previousSets, id: \.self) { set in
                            HStack {
                                Text("Подход \(set.setNumber)")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f кг × %d", set.weight, set.reps))
                                    .font(DesignSystem.Typography.callout())
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        }
                    }
                    
                    Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                }
                
                // Completed sets (editable)
                if !completedSets.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("ВЫПОЛНЕНО")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        ForEach(completedSets, id: \.id) { set in
                            CompletedSetRow(
                                set: set,
                                isExtra: set.setNumber > exercise.plannedSets,
                                onEdit: {
                                    startEditing(set)
                                },
                                onDelete: {
                                    deleteSet(set)
                                }
                            )
                        }
                    }
                    
                    Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                }
                
                // Current set input or "Add More" button
                if showingInput {
                    CurrentSetInput(
                        setNumber: currentSetNumber,
                        weight: $weight,
                        reps: $reps,
                        duration: $duration,
                        rounds: $rounds,
                        workoutType: workoutType,
                        isExtra: isExtra,
                        canSave: canSave,
                        elapsedTime: $elapsedTime,
                        timerRunning: $timerRunning,
                        onSave: saveCurrentSet
                    )
                } else if completedSets.count >= exercise.plannedSets {
                    // Comment Section
                    if !exerciseComment.isEmpty {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "text.bubble.fill")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text(exerciseComment)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .italic()
                            
                            Spacer()
                            
                            Button("Изменить") {
                                showingComment = true
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.accent)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    } else {
                        Button(action: { showingComment = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "text.bubble")
                                    .font(.caption2)
                                Text("Добавить комментарий")
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    
                    // Show "Add More" button after completing planned sets
                    Button(action: {
                        showingInput = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Ещё подход")
                                .font(DesignSystem.Typography.headline())
                        }
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .onAppear {
            // Show input initially if no sets completed yet
            if completedSets.count < exercise.plannedSets {
                showingInput = true
            }
        }
        .onChange(of: completedSets.count) { _, _ in
            // Auto-show next input after completing a set (if not all done)
            if completedSets.count < exercise.plannedSets {
                showingInput = true
            } else {
                showingInput = false
            }
        }
        .sheet(isPresented: $showingReplacement) {
            ExerciseSelectionView(onExerciseSelected: { newExercise in
                replaceExercise(with: newExercise)
                showingReplacement = false
            })
        }
        .sheet(isPresented: $showingComment) {
            CommentEditorView(comment: $exerciseComment)
        }
        .sheet(isPresented: $showingWorkoutTypeChange) {
            WorkoutTypeSelectorView(
                selectedType: Binding(
                    get: { workoutType },
                    set: { newType in
                        // Update exercise workout type
                        // Note: This changes the whole day's type since it's at day level
                    }
                ),
                onSelect: { newType in
                    // Could update individual exercise type if model supports it
                    showingWorkoutTypeChange = false
                }
            )
        }
    }
    
    private func saveCurrentSet() {
        guard let session = session else { return }
        
        let set: WorkoutSet
        
        switch workoutType {
        case .strength:
            guard let weightValue = Double(weight),
                  let repsValue = Int(reps),
                  weightValue > 0,
                  repsValue > 0 else { return }
            
            set = WorkoutSet(
                exerciseName: exercise.name,
                weight: weightValue,
                reps: repsValue,
                setNumber: currentSetNumber
            )
            
        case .circuit:
            guard let roundsValue = Int(rounds),
                  let durationValue = Double(duration),
                  roundsValue > 0,
                  durationValue > 0 else { return }
            
            set = WorkoutSet(
                exerciseName: exercise.name,
                weight: 0,
                reps: roundsValue, // Используем reps для кругов
                setNumber: currentSetNumber
            )
            set.duration = durationValue
            
        case .cardio:
            guard let durationValue = Double(duration),
                  durationValue > 0 else { return }
            
            set = WorkoutSet(
                exerciseName: exercise.name,
                weight: 0,
                reps: 0,
                setNumber: currentSetNumber
            )
            set.duration = elapsedTime > 0 ? elapsedTime : durationValue
        }
        
        set.isCompleted = true
        set.session = session
        
        modelContext.insert(set)
        session.sets.append(set)
        
        try? modelContext.save()
        
        // Clear inputs
        weight = ""
        reps = ""
        duration = ""
        rounds = ""
        elapsedTime = 0
        timerRunning = false
    }
    
    private func replaceExercise(with newExercise: LibraryExercise) {
        // Update the exercise template name to the new exercise
        exercise.name = newExercise.name
        
        // Update all existing sets for this exercise
        for set in completedSets {
            set.exerciseName = newExercise.name
        }
        
        try? modelContext.save()
    }
    
    private func startEditing(_ set: WorkoutSet) {
        weight = String(format: "%.0f", set.weight)
        reps = "\(set.reps)"
        deleteSet(set)
        showingInput = true
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        guard let session = session else { return }
        
        if let index = session.sets.firstIndex(of: set) {
            session.sets.remove(at: index)
        }
        
        modelContext.delete(set)
        try? modelContext.save()
    }
}

// MARK: - Current Set Input

struct CurrentSetInput: View {
    let setNumber: Int
    @Binding var weight: String
    @Binding var reps: String
    @Binding var duration: String
    @Binding var rounds: String
    let workoutType: WorkoutType
    let isExtra: Bool
    let canSave: Bool
    @Binding var elapsedTime: TimeInterval
    @Binding var timerRunning: Bool
    let onSave: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var timer: Timer?
    
    enum Field {
        case weight, reps, duration, rounds
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("ПОДХОД \(setNumber)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                if isExtra {
                    Text("ДОПОЛНИТЕЛЬНЫЙ")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
            
            // Timer display (for circuit and cardio only)
            if workoutType == .circuit || workoutType == .cardio {
                HStack {
                    Spacer()
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
                
                // Timer controls
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button(action: toggleTimer) {
                        Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(timerRunning ? .white : .black) // Black icon on neon green
                            .frame(width: 60, height: 44)
                            .background(timerRunning ? .orange : DesignSystem.Colors.neonGreen)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 44)
                            .background(DesignSystem.Colors.secondaryText)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                }
            }
            
            // Input fields based on workout type
            HStack(spacing: DesignSystem.Spacing.md) {
                switch workoutType {
                case .strength:
                    strengthInputs
                    
                case .circuit:
                    circuitInputs
                    
                case .cardio:
                    cardioInputs
                }
                
                // Confirm button
                Button(action: onSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(canSave ? .black : DesignSystem.Colors.secondaryText)
                        .frame(width: 44, height: 44)
                        .background(canSave ? DesignSystem.Colors.neonGreen : DesignSystem.Colors.secondaryText.opacity(0.3))
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            switch workoutType {
            case .strength:
                focusedField = .weight
            case .circuit:
                focusedField = .rounds
            case .cardio:
                timerRunning = true
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Strength Inputs
    
    private var strengthInputs: some View {
        Group {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("ВЕС (КГ)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(weight.isEmpty ? DesignSystem.Colors.secondaryText.opacity(0.3) : DesignSystem.Colors.neonGreen, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .weight)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("ПОВТОРЫ")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $reps)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(reps.isEmpty ? DesignSystem.Colors.secondaryText.opacity(0.3) : DesignSystem.Colors.neonGreen, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .reps)
            }
        }
    }
    
    // MARK: - Circuit Inputs
    
    private var circuitInputs: some View {
        Group {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("КРУГОВ")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $rounds)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(rounds.isEmpty ? DesignSystem.Colors.secondaryText.opacity(0.3) : DesignSystem.Colors.neonGreen, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .rounds)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("ВРЕМЯ (МИН)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $duration)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(duration.isEmpty ? DesignSystem.Colors.secondaryText.opacity(0.3) : DesignSystem.Colors.neonGreen, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .duration)
            }
        }
    }
    
    // MARK: - Cardio Inputs
    
    private var cardioInputs: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Используйте таймер выше")
                .font(DesignSystem.Typography.callout())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Timer Functions
    
    private func toggleTimer() {
        timerRunning.toggle()
        
        if timerRunning {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerRunning {
                elapsedTime += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        elapsedTime = 0
        timerRunning = false
        stopTimer()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Completed Set Row

struct CompletedSetRow: View {
    let set: WorkoutSet
    let isExtra: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Text("Подход \(set.setNumber)")
                .font(DesignSystem.Typography.callout())
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            if isExtra {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.neonGreen)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Text(String(format: "%.0f кг × %d", set.weight, set.reps))
                    .font(DesignSystem.Typography.callout())
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Image(systemName: "checkmark")
                .foregroundColor(DesignSystem.Colors.neonGreen)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}
