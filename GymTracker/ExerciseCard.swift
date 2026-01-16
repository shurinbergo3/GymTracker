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
    let workoutType: WorkoutType // Тип тренировки по умолчанию (от дня)
    var aiRecommendation: String? = nil // Optional AI recommendation text
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var duration: String = "" // Для Duration
    @State private var distance: String = "" // Для Duration (опционально)
    @State private var showingInput: Bool = false
    @State private var elapsedTime: TimeInterval = 0 // Таймер
    @State private var timerRunning: Bool = false
    @State private var showingReplacement = false // Для замены упражнения
    @State private var showingComment = false // Для комментария
    @State private var showingTechnique = false // Для техники
    @State private var exerciseComment: String = "" // Комментарий к упражнению
    @State private var showingWorkoutTypeChange = false // Для смены типа тренировки
    @State private var showingMenu = false // Для показа меню действий
    @State private var currentWorkoutType: WorkoutType? = nil // Тип для этого конкретного упражнения
    @State private var isHistoryExpanded: Bool = false // Для аккордеона истории
    @State private var isWeighted: Bool = false // Для упражнений с собственным весом (доп. вес)
    
    // Используем локальный тип если установлен, иначе тип дня
    private var effectiveWorkoutType: WorkoutType {
        currentWorkoutType ?? workoutType
    }
    
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
        switch effectiveWorkoutType {
        case .strength:
            return !weight.isEmpty && !reps.isEmpty
        case .repsOnly:
            return !reps.isEmpty
        case .duration:
            return !duration.isEmpty || elapsedTime > 0
        }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Exercise Name with Info and Replace Buttons
                HStack(spacing: DesignSystem.Spacing.sm) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(exercise.name)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                    
                    Spacer()
                    
                    // Menu Button
                    Button(action: { showingMenu = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    
                    Text("\(exercise.plannedSets) подходов")
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Accordion History
                if !previousSets.isEmpty {
                ExerciseInlineHistoryView(
                    previousSets: previousSets,
                    isExpanded: $isHistoryExpanded,
                    onAutoFill: { set in
                        weight = String(format: "%.0f", set.weight)
                        reps = "\(set.reps)"
                        if let dur = set.duration { duration = "\(Int(dur))" }
                    }
                )
                
                Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                }
                
                // AI Recommendation Banner (Hidden if nil)
                if let recommendation = aiRecommendation {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.system(size: 16, weight: .bold))
                            .shadow(color: .purple.opacity(0.8), radius: 5)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI PEKOMEНДАЦИЯ")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                                .tracking(1)
                            
                            Text(recommendation)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.purple.opacity(0.2), Color.black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                
                // Completed sets (editable)
                if !completedSets.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Выполнено")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        ForEach(completedSets, id: \.id) { set in
                            CompletedSetRow(
                                set: set,
                                isExtra: set.setNumber > exercise.plannedSets,
                                workoutType: effectiveWorkoutType,
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
                        distance: $distance,
                        workoutType: effectiveWorkoutType,
                        isExtra: isExtra,
                        canSave: canSave,
                        elapsedTime: $elapsedTime,
                        timerRunning: $timerRunning,
                        isWeighted: $isWeighted, // New binding
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
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
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
        // Active State Glow
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(showingInput ? DesignSystem.Colors.neonGreen.opacity(0.5) : Color.clear, lineWidth: 2)
                .padding(.horizontal, DesignSystem.Spacing.lg) // Match padding
        )
        .shadow(color: showingInput ? DesignSystem.Colors.neonGreen.opacity(0.2) : Color.clear, radius: 15)
        .onAppear {
            // Show input initially if no sets completed yet
            if completedSets.count < exercise.plannedSets {
                showingInput = true
            }
            // Загружаем комментарий из первого сета
            if let firstSet = completedSets.first, let comment = firstSet.comment {
                exerciseComment = comment
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
        .onChange(of: exerciseComment) { _, newComment in
            // Сохраняем комментарий в первый сет
            if let firstSet = completedSets.first {
                firstSet.comment = newComment.isEmpty ? nil : newComment
                try? modelContext.save()
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
        .sheet(isPresented: $showingTechnique) {
            ExerciseTechniqueDetailView(exerciseName: exercise.name, technique: ExerciseLibrary.getTechnique(for: exercise.name))
        }
        .sheet(isPresented: $showingWorkoutTypeChange) {
            WorkoutTypeSelectorView(
                selectedType: Binding(
                    get: { effectiveWorkoutType },
                    set: { newType in
                        currentWorkoutType = newType
                    }
                ),
                onSelect: { newType in
                    currentWorkoutType = newType
                    showingWorkoutTypeChange = false
                }
            )
        }
        .confirmationDialog("Действия", isPresented: $showingMenu, titleVisibility: .hidden) {
            Button("Техника упражнения") {
                showingTechnique = true
            }
            Button("Заменить упражнение") {
                showingReplacement = true
            }
            Button("Изменить тип упражнения") {
                showingWorkoutTypeChange = true
            }
            Button("Комментарий") {
                showingComment = true
            }
            Button("Отмена", role: .cancel) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private func saveCurrentSet() {
        guard let session = session else { return }
        
        let set: WorkoutSet
        
        switch effectiveWorkoutType {
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
            
        case .repsOnly:
            guard let repsValue = Int(reps),
                  repsValue > 0 else { return }
            
            let weightValue = isWeighted ? (Double(weight) ?? 0) : 0
            
            set = WorkoutSet(
                exerciseName: exercise.name,
                weight: weightValue,
                reps: repsValue,
                setNumber: currentSetNumber,
                isWeighted: isWeighted
            )
            
        case .duration:
            let durationValue = Double(duration) ?? 0
            // Distance is optional
            let distanceValue = Double(distance)
            
            // Should have either duration entered OR timer running logic
            let finalDuration = elapsedTime > 0 ? elapsedTime : durationValue
            
            guard finalDuration > 0 else { return }
            
            set = WorkoutSet(
                exerciseName: exercise.name,
                weight: 0,
                reps: 0,
                setNumber: currentSetNumber
            )
            set.duration = finalDuration
            set.distance = distanceValue
        }
        
        // Если это первый сет, сохраняем комментарий
        if completedSets.isEmpty && !exerciseComment.isEmpty {
            set.comment = exerciseComment
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
        distance = ""
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
        isWeighted = set.isWeighted
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

// MARK: - Current Set Input

struct CurrentSetInput: View {
    let setNumber: Int
    @Binding var weight: String
    @Binding var reps: String
    @Binding var duration: String
    @Binding var distance: String
    let workoutType: WorkoutType
    let isExtra: Bool
    let canSave: Bool
    @Binding var elapsedTime: TimeInterval
    @Binding var timerRunning: Bool
    @Binding var isWeighted: Bool // New
    let onSave: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var timer: Timer?
    
    enum Field {
        case weight, reps, duration, distance
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Подход \(setNumber)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                if isExtra {
                    Text("Дополнительный")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.neonGreen.opacity(0.2))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
            
            // Timer display (for duration only)
            if workoutType == .duration {
                // ... (existing timer code omitted for brevity logic below, ensuring context match)
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
                    
                case .repsOnly:
                    repsOnlyInputs
                    
                case .duration:
                    durationInputs
                }
                
                // Confirm button
                Button(action: onSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(canSave ? .black : DesignSystem.Colors.neonGreen) // Icon color
                        .frame(width: 44, height: 44)
                        .background(canSave ? DesignSystem.Colors.neonGreen : Color.clear) // BG Color
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        // Outline for unselected state
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.neonGreen, lineWidth: canSave ? 0 : 2)
                        )
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            switch workoutType {
            case .strength, .repsOnly:
                break
            case .duration:
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
                Text("Вес (кг)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(Color(uiColor: .systemGray6).opacity(0.2)) // Updated BG
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(focusedField == .weight ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3), lineWidth: 1) // Updated Border
                    )
                    .focused($focusedField, equals: .weight)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Повторы")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $reps)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(Color(uiColor: .systemGray6).opacity(0.2)) // Updated BG
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(focusedField == .reps ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3), lineWidth: 1) // Updated Border
                    )
                    .focused($focusedField, equals: .reps)
            }
        }
    }
    
    // MARK: - Reps Only Inputs
    
    private var repsOnlyInputs: some View {
        Group {
            if isWeighted {
                // If weighted, show Weight field + Reps field (Same as strength)
                strengthInputs
                    .overlay(
                         // Small minus button to remove weight
                         Button(action: {
                             isWeighted = false
                             weight = "" // Clear weight
                         }) {
                             Image(systemName: "minus.circle.fill")
                                 .foregroundColor(.red)
                                 .font(.caption)
                                 .background(Color.black.clipShape(Circle()))
                         }
                         .offset(x: -5, y: -5), // Position relative to top-left of the group? No, hard to position
                         alignment: .topLeading
                    )
            } else {
                // Determine if we need to show the toggle button
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Повторы")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        // Add Weight Button
                        Button(action: {
                            isWeighted = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                Text("Вес")
                                    .font(.caption2)
                            }
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                        }
                    }
                    
                    TextField("", text: $reps)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(height: 44)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .background(Color(uiColor: .systemGray6).opacity(0.2)) // Updated BG
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(focusedField == .reps ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .reps)
                }
            }
        }
    }
    
    // MARK: - Duration Inputs
    
    private var durationInputs: some View {
        Group {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Время (сек)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $duration)
                    .keyboardType(.numberPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(Color(uiColor: .systemGray6).opacity(0.2)) // Updated BG
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(focusedField == .duration ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .duration)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Дист. (км, опц.)")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("", text: $distance)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(height: 44)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .background(Color(uiColor: .systemGray6).opacity(0.2)) // Updated BG
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(focusedField == .distance ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .distance)
            }
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

// MARK: - Completed Set Row

struct CompletedSetRow: View {
    let set: WorkoutSet
    let isExtra: Bool
    let workoutType: WorkoutType
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
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
                HStack(spacing: 4) {
                    formattedSetText
                }
                .font(DesignSystem.Typography.callout())
                .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Image(systemName: "checkmark")
                .foregroundColor(DesignSystem.Colors.neonGreen)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Удалить", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Редактировать", systemImage: "pencil")
            }
        }
    }
    
    @ViewBuilder
    private var formattedSetText: some View {
        switch workoutType {
        case .strength:
            Text(String(format: "%.0f кг", set.weight))
            Text("×")
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text("\(set.reps)")
            
        case .repsOnly:
            if set.isWeighted {
                HStack(spacing: 4) {
                    Text("\(set.reps) повт.")
                    Text("+")
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text(String(format: "%.0fкг", set.weight)) // Removed unnecessary space
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            } else {
                Text("\(set.reps) повт.")
            }
            
        case .duration:
            if let dur = set.duration {
                Text(formatTime(dur))
            }
            if let dist = set.distance, dist > 0 {
                Text("(\(String(format: "%.1f", dist)) км)")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Inline History View

struct ExerciseInlineHistoryView: View {
    let previousSets: [WorkoutSet]
    @Binding var isExpanded: Bool
    let onAutoFill: (WorkoutSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "История" : "Прошлый раз")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    if !isExpanded, let lastSet = previousSets.last {
                        // Collapsed view: show brief summary of last set
                        HStack(spacing: 4) {
                            if lastSet.weight > 0 {
                                Text(String(format: "%.0fкг", lastSet.weight))
                            }
                            if lastSet.reps > 0 {
                                Text("× \(lastSet.reps)")
                            }
                            if let lastDate = lastSet.session?.date {
                                Text("(\(formatDate(lastDate)))")
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                            }
                        }
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(previousSets.prefix(5), id: \.self) { set in
                        Button(action: { onAutoFill(set) }) {
                            HStack {
                                Text(formatDate(set.date))
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .frame(width: 60, alignment: .leading)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    if set.weight > 0 {
                                        Text(String(format: "%.0f кг", set.weight))
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                    }
                                    if set.reps > 0 && set.weight > 0 {
                                        Text("×")
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                    if set.reps > 0 {
                                        Text("\(set.reps) повт.")
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                    }
                                    if let dur = set.duration, dur > 0 {
                                        Text(formatTime(dur))
                                            .foregroundColor(DesignSystem.Colors.primaryText)
                                    }
                                }
                                .font(DesignSystem.Typography.callout())
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(DesignSystem.Colors.secondaryText.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
