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
    @EnvironmentObject var workoutManager: WorkoutManager
    let exercise: ExerciseTemplate
    let programName: String
    let session: WorkoutSession?
    let workoutType: WorkoutType
    let isActive: Bool // Focus Mode
    var allCompletedSessions: [WorkoutSession] = []
    var aiRecommendation: String? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var duration: String = ""
    @State private var distance: String = ""
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerRunning: Bool = false
    @State private var showingReplacement = false
    @State private var showingComment = false
    @State private var showingTechnique = false
    @State private var exerciseComment: String = ""
    @State private var showingWorkoutTypeChange = false
    @State private var currentWorkoutType: WorkoutType? = nil
    @State private var isHistoryExpanded: Bool = true // Expanded by default
    @State private var isWeighted: Bool = false
    @State private var showRestTimer: Bool = false
    @State private var isTimerEnabledForExercise: Bool = true // Timer toggle state
    
    @State private var timer: Timer? = nil
    
    // Cached expensive computation - computed once in onAppear, not on every render
    @State private var cachedPreviousSets: [WorkoutSet] = []
    // Sets from the workout BEFORE the previous one (used to label per-set progression
    // shown in the "Прошлая тренировка" block). Nil for first / second occurrence.
    @State private var cachedPenultimateSets: [WorkoutSet] = []
    // All-time best estimated 1RM for this exercise across completed sessions.
    // 0 when there is no data or the exercise isn't a strength exercise.
    @State private var personalBestE1RM: Double = 0
    
    // Derived properties
    private var effectiveWorkoutType: WorkoutType {
        currentWorkoutType ?? workoutType
    }
    
    private var previousSets: [WorkoutSet] {
        cachedPreviousSets
    }
    
    private var completedSets: [WorkoutSet] {
        guard let session = session else { return [] }
        return session.sets
            .filter { $0.exerciseName == exercise.name }
            .sorted { 
                // Сортируем сначала по времени создания, потом по номеру подхода
                if $0.date != $1.date {
                    return $0.date < $1.date
                }
                return $0.setNumber < $1.setNumber
            }
    }
    
    private var currentSetNumber: Int {
        completedSets.count + 1
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
        VStack(spacing: 0) {
            // Rest Timer (shown after set completion)
            if showRestTimer, isTimerEnabledForExercise {
                RestTimerView(
                    isPresented: $showRestTimer,
                    defaultDuration: exercise.workoutDay?.defaultRestTime ?? 90,
                    autoStart: true
                )
                .padding(.top, 8)
            }
            // MARK: - Header (Title + Icons)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(exercise.name.localized())
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    // Progress Pills / Boxes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let totalCount = max(1, max(exercise.plannedSets, completedSets.count)) // Защита от диапазона 1...0 при plannedSets=0

                            ForEach(1...totalCount, id: \.self) { setNum in
                                let isCompleted = setNum <= completedSets.count
                                let isExtra = setNum > exercise.plannedSets
                                let isCurrent = setNum == completedSets.count + 1
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(
                                            isCompleted ? (isExtra ? DesignSystem.Colors.secondaryAccent : DesignSystem.Colors.neonGreen) :
                                                (isCurrent ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                        )
                                        .frame(width: 32, height: 32)
                                        .shadow(color: isCompleted ? (isExtra ? DesignSystem.Colors.secondaryAccent : DesignSystem.Colors.neonGreen).opacity(0.4) : .clear, radius: 4)
                                    
                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.black)
                                    } else {
                                        Text("\(setNum)")
                                            .font(DesignSystem.Typography.monospaced(.caption, weight: .bold))
                                            .foregroundColor(isCurrent ? .white : .gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Header Actions
                HStack(spacing: 16) {
                    if !previousSets.isEmpty {
                        Button(action: { withAnimation { isHistoryExpanded.toggle() } }) {
                            Image(systemName: "clock.arrow.circlepath") // History
                                .font(.system(size: 18))
                                .foregroundColor(isHistoryExpanded ? DesignSystem.Colors.neonGreen : .gray)
                        }
                    }
                    
                    Button(action: { showingTechnique = true }) {
                        Image(systemName: "info.circle") // Info/Technique
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    // Menu Button
                    Menu {
                        Button {
                            isTimerEnabledForExercise.toggle()
                            // If turning off, hide any active timer immediately
                            if !isTimerEnabledForExercise {
                                showRestTimer = false
                            } else {
                                showRestTimer = true
                            }
                        } label: {
                            Label(
                                (isTimerEnabledForExercise ? "Выключить таймер" : "Включить таймер").localized(),
                                systemImage: isTimerEnabledForExercise ? "timer.circle.fill" : "timer.circle"
                            )
                        }
                        
                        Divider()
                        
                        Button(action: { showingReplacement = true }) {
                            Label("Заменить упражнение".localized(), systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(action: { showingWorkoutTypeChange = true }) {
                            Label("Изменить тип".localized(), systemImage: "gearshape")
                        }
                        
                        if let onDelete {
                            Divider()
                            Button(role: .destructive, action: onDelete) {
                                Label("Удалить упражнение".localized(), systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 44, height: 44) // Larger tap area
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(16)
            
            // MARK: - History Block
            if isHistoryExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Прошлая тренировка:".localized())
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        if personalBestE1RM > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                Text("\("Макс.".localized()) \(formatBest(personalBestE1RM)) \("кг".localized()) e1RM")
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                            }
                        }
                    }

                    ForEach(previousSets, id: \.self) { set in
                        let priorPeer = cachedPenultimateSets.first { $0.setNumber == set.setNumber }
                        let progression = SetProgression.compare(current: set, prior: priorPeer)
                        HStack(spacing: 8) {
                            Text("\("Подход".localized()) \(set.setNumber):")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if (set.duration ?? 0) > 0 {
                                Text(formatTime(set.duration ?? 0))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            } else {
                                Text(String(format: "%@кг x %d".localized(), set.weight.formatted(), set.reps))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            if progression != .noBaseline {
                                Image(systemName: progression.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(progression.color)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
            
            // MARK: - Current Session Sets (NEW)
            if !completedSets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("completed_colon".localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(completedSets, id: \.self) { set in
                                let priorPeer = cachedPreviousSets.first { $0.setNumber == set.setNumber }
                                let progression = SetProgression.compare(current: set, prior: priorPeer)
                                CompletedSetChip(
                                    set: set,
                                    workoutType: effectiveWorkoutType,
                                    progression: progression
                                )
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteSet(set)
                                        } label: {
                                            Label("Удалить".localized(), systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
            
            // MARK: - AI Banner
            if isActive, let recommendation = aiRecommendation {
                HStack {
                    Text("AI: \(recommendation)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .background(
                    Capsule()
                        .stroke(Color.purple, lineWidth: 1)
                        .background(Color.purple.opacity(0.2).clipShape(Capsule()))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // MARK: - Main Content (Inputs) - ONLY IF ACTIVE
            if isActive {
                VStack(spacing: 16) {
                    
                    // Input Fields based on Type
                    switch effectiveWorkoutType {
                    case .strength:
                        HStack(spacing: 12) {
                            // Weight Input
                            VStack(spacing: 6) {
                                Text("Вес (кг)".localized().uppercased())
                                    .font(DesignSystem.Typography.sectionHeader())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.0)
                                
                                TextField("0", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(DesignSystem.Typography.monospaced(.title, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .frame(height: 70)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            
                            // Reps Input
                            VStack(spacing: 6) {
                                Text("ПОВТОРЫ".localized())
                                    .font(DesignSystem.Typography.sectionHeader())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.0)
                                
                                TextField("0", text: $reps)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(DesignSystem.Typography.monospaced(.title, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .frame(height: 70)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                        }
                        
                    case .repsOnly:
                        VStack(spacing: 12) {
                            // Single Large Reps Input
                            VStack(spacing: 6) {
                                Text("ПОВТОРЫ".localized())
                                    .font(DesignSystem.Typography.sectionHeader())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .tracking(1.0)
                                
                                TextField("0", text: $reps)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(DesignSystem.Typography.monospaced(.largeTitle, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                    .frame(height: 100)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(DesignSystem.CornerRadius.large)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            
                            // Weighted Toggle Button
                            HStack {
                                if isWeighted {
                                    HStack {
                                        TextField("weight_label", text: $weight)
                                            .keyboardType(.decimalPad)
                                            .frame(width: 60)
                                            .multilineTextAlignment(.center)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                        
                                        Button(action: { isWeighted = false; weight = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                } else {
                                    Button(action: { isWeighted = true }) {
                                        Text("add_weight_button".localized())
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(DesignSystem.Colors.neonGreen)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                    case .duration:
                        VStack(spacing: 16) {
                            // Large Timer Display
                            HStack(spacing: 20) {
                                Text(elapsedTime > 0 ? formatTime(elapsedTime) : (duration.isEmpty ? "00:00" : duration))
                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Button(action: toggleTimer) {
                                    Image(systemName: timerRunning ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(timerRunning ? .orange : DesignSystem.Colors.neonGreen)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            
                            // Distance Input (Optional)
                            HStack {
                                Text("КМ".localized())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("--", text: $distance)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Display Note if exists
                    if !exerciseComment.isEmpty {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                            Text(exerciseComment)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: { exerciseComment = "" }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // NOTE & SAVE FOOTER
                    HStack {
                        Button("Заметка".localized()) {
                            showingComment = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Show "Дополнительный подход" Label if we are on the last set or extra set
                        if completedSets.count >= exercise.plannedSets - 1 {
                             Text("ДОП. ПОДХОД".localized())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.secondaryAccent)
                                .padding(.trailing, 16)
                                .opacity(completedSets.count >= exercise.plannedSets ? 1.0 : 0.0)
                        }
                        
                        // Large Check Button
                        Button(action: saveCurrentSet) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(canSave ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .shadow(color: canSave ? DesignSystem.Colors.neonGreen.opacity(0.4) : .clear, radius: 12)
                        }
                        .disabled(!canSave)
                    }
                    .padding(.top, 12)
                }
                .padding(16)
            } else {
                // Inactive State Summary
                if !completedSets.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "Выполнено: %1$d / %2$d".localized(), completedSets.count, exercise.plannedSets))
                            .font(DesignSystem.Typography.monospaced(.caption, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        // Focus Mode Styles
        .opacity(isActive ? 1.0 : 0.6)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isActive ? DesignSystem.Colors.neonGreen.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        // Sheets & Actions
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
            ExerciseTechniqueDetailView(exerciseName: exercise.name)
        }
        .sheet(isPresented: $showingWorkoutTypeChange) {
            WorkoutTypeSelectorView(
                selectedType: Binding(
                    get: { effectiveWorkoutType },
                    set: { newType in currentWorkoutType = newType }
                ),
                onSelect: { newType in
                    currentWorkoutType = newType
                    showingWorkoutTypeChange = false
                }
            )
        }
        .onAppear {
            // Compute previousSets once (expensive: filters all sessions)
            // Subsequent renders use cachedPreviousSets instead of recomputing
            let sessionsWithExercise = allCompletedSessions
                .filter { session in
                    guard session.id != self.session?.id else { return false }
                    return session.sets.contains { $0.exerciseName == exercise.name }
                }
                .sorted { $0.date > $1.date }
            if let lastSession = sessionsWithExercise.first {
                cachedPreviousSets = lastSession.sets
                    .filter { $0.exerciseName == exercise.name }
                    .sorted {
                        if $0.date != $1.date { return $0.date < $1.date }
                        return $0.setNumber < $1.setNumber
                    }
            }
            if sessionsWithExercise.count >= 2 {
                let penultimate = sessionsWithExercise[1]
                cachedPenultimateSets = penultimate.sets
                    .filter { $0.exerciseName == exercise.name }
                    .sorted {
                        if $0.date != $1.date { return $0.date < $1.date }
                        return $0.setNumber < $1.setNumber
                    }
            }
            // All-time best estimated 1RM across every prior session.
            var best: Double = 0
            for session in sessionsWithExercise {
                for set in session.sets where set.exerciseName == exercise.name {
                    guard set.weight > 0, set.reps > 0 else { continue }
                    let e1RM = set.weight * (1.0 + Double(set.reps) / 30.0)
                    if e1RM > best { best = e1RM }
                }
            }
            personalBestE1RM = best
            
            if let firstSet = completedSets.first, let comment = firstSet.comment {
                exerciseComment = comment
            }
            if isActive && weight.isEmpty {
                if let lastSet = cachedPreviousSets.last {
                    let w = lastSet.weight
                    if w.truncatingRemainder(dividingBy: 1) == 0 {
                        weight = String(format: "%.0f", w)
                    } else {
                        weight = String(format: "%.1f", w)
                    }
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
             if newValue {
                 // Auto-expand history if active? Maybe just keep user choice.
             }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Logic Helpers
    
    private func saveCurrentSet() {
        guard let session = session else { return }
        
        // Validation Logic
        let weightVal = Double(weight.replacingOccurrences(of: ",", with: ".")) ?? 0
        let repsVal = Int(reps) ?? 0
        
        // Basic check based on type
        if effectiveWorkoutType == .strength && (weight.isEmpty || reps.isEmpty) { return }
        if effectiveWorkoutType == .repsOnly && reps.isEmpty { return }
        
        let set = WorkoutSet(exerciseName: exercise.name, 
                             weight: weightVal, 
                             reps: repsVal, 
                             setNumber: currentSetNumber, 
                             isWeighted: isWeighted)
        
        if effectiveWorkoutType == .duration {
            set.duration = elapsedTime > 0 ? elapsedTime : (Double(duration) ?? 0)
            set.distance = Double(distance)
        }

        // PR detection (Epley 1RM): compare to all-time best for this exercise.
        // Only meaningful for strength sets with weight > 0 and reps > 0.
        var isPR = false
        if effectiveWorkoutType == .strength,
           weightVal > 0, repsVal > 0,
           personalBestE1RM > 0 {
            let newE1RM = weightVal * (1.0 + Double(repsVal) / 30.0)
            // 0.5 kg buffer to avoid noise from rounding
            if newE1RM > personalBestE1RM + 0.5 {
                isPR = true
            }
        }

        if isPR {
            // Heavier haptic for personal record — feels different from a normal set.
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        if !exerciseComment.isEmpty {
            set.comment = exerciseComment
            // Keep comment for next set? Usually notes are per-exercise.
        }
        
        set.isCompleted = true
        set.session = session
        
        modelContext.insert(set)
        session.sets.append(set)
        try? modelContext.save()

        // Notify the gamification strip so it can pulse / flash for a PR.
        workoutManager.notifySetCompleted(isPR: isPR)
        
        // Start rest timer only if NOT the last planned set
        // Don't start timer if user just completed their last planned set
        let isLastPlannedSet = completedSets.count >= exercise.plannedSets
        
        if isTimerEnabledForExercise && !isLastPlannedSet {
            withAnimation {
                showRestTimer = true
            }
        }
        
        // Reset Inputs
        reps = ""
        duration = ""
        elapsedTime = 0
        timerRunning = false
        // weight stays
    }
    
    private func replaceExercise(with newExercise: LibraryExercise) {
        // Logic to update template name
        exercise.name = newExercise.name
        // Update existing sets name ? Not strictly required if sets are by name, but good for consistency
        for set in completedSets { set.exerciseName = newExercise.name }
        try? modelContext.save()
    }
    
    private func toggleTimer() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        timerRunning.toggle()
        if timerRunning {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timerRunning { elapsedTime += 1 }
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        guard let session = session else { return }
        
        withAnimation {
            // Remove from session local array if needed (SwiftData might handle relationship automation but manual update ensures UI refresh)
            if let index = session.sets.firstIndex(where: { $0.id == set.id }) {
                session.sets.remove(at: index)
            }
            
            // Delete from context
            modelContext.delete(set)
            
            // Re-number remaining sets for this exercise, sorted by creation time and set number
            let exerciseSets = session.sets
                .filter { $0.exerciseName == exercise.name }
                .sorted { 
                    if $0.date != $1.date {
                        return $0.date < $1.date
                    }
                    return $0.setNumber < $1.setNumber
                }
            
            for (index, s) in exerciseSets.enumerated() {
                s.setNumber = index + 1
            }
            
            try? modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatBest(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Completed Set Chip Component

struct CompletedSetChip: View {
    let set: WorkoutSet
    let workoutType: WorkoutType
    var progression: SetProgression = .noBaseline

    var body: some View {
        HStack(spacing: 6) {
            // Set number badge
            Text("\(set.setNumber)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(DesignSystem.Colors.neonGreen)
                .clipShape(Circle())
            
            // Set details
            Text(setDetails)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            if progression != .noBaseline {
                Image(systemName: progression.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(progression.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var setDetails: String {
        switch workoutType {
        case .strength:
            return "\(formattedWeight)\("кг".localized()) × \(set.reps)"
        case .repsOnly:
            if set.weight > 0 {
                return "\(formattedWeight)\("кг".localized()) × \(set.reps)"
            } else {
                return "\(set.reps) \("повт.".localized())"
            }
        case .duration:
            if let duration = set.duration, duration > 0 {
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            } else {
                return "Готово".localized()
            }
        }
    }

    private var formattedWeight: String {
        let w = set.weight
        if w.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", w)
        } else {
            return String(format: "%.1f", w)
        }
    }
}
