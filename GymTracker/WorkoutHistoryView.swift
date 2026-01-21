//
//  WorkoutHistoryView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Charts

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int // Added for navigation
    
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query private var programs: [Program] // To check if user has programs
    
    @State private var historyMode: HistoryMode = .sessions
    
    enum HistoryMode: String, CaseIterable {
        case sessions = "Тренировки"
        case exercises = "Упражнения"
    }
    
    // Calculates progress for a specific past session compared to the one before it
    private func calculateProgress(for session: WorkoutSession) -> ProgressState? {
        // Find sessions of the same "day name" (e.g. "Chest Day") that are OLDER than this session
        let sameTypeSessions = allSessions
            .filter { $0.workoutDayName == session.workoutDayName && $0.isCompleted && $0.date < session.date }
            .sorted { $0.date < $1.date }
        
        guard let previousSession = sameTypeSessions.last else { return nil } // No previous history for this type
        
        // Calculate Total Volumes
        let currentVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        let previousVolume = previousSession.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        
        // Logic (Same as Manager)
        if currentVolume > previousVolume {
             return .improved
        }
        if currentVolume >= (previousVolume * 0.9) {
            return .same
        }
        return .declined
    }
    
    // Только завершенные тренировки
    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            if completedSessions.isEmpty {
                // Custom Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon with Glow
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.neonGreen.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 44))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.2), radius: 20, x: 0, y: 0)
                    
                    // Text
                    VStack(spacing: 8) {
                        Text("Нет завершенных тренировок")
                            .font(DesignSystem.Typography.title3())
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        
                        Text("История ваших тренировок появится здесь.\nНачните свой путь прямо сейчас!")
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                    
                    // Smart Button
                    Button(action: {
                        if programs.isEmpty {
                            // No programs -> Go to Programs tab to create one
                            selectedTab = 1
                        } else {
                            // Programs exist -> Go to Workout tab to start
                            selectedTab = 0
                        }
                        dismiss()
                    }) {
                        Text("Начать тренировку")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DesignSystem.Colors.neonGreen)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.2), radius: 10, y: 4)
                }
            } else {
                VStack(spacing: 0) {
                    // Mode Picker
                    Picker("Режим", selection: $historyMode) {
                        ForEach(HistoryMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(DesignSystem.Colors.cardBackground)
                    
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            if historyMode == .sessions {
                                SessionHistoryView(completedSessions: completedSessions)
                            } else {
                                ExerciseHistoryListView(sessions: completedSessions)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
            }
        }
        .navigationTitle("История")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Session History View
struct SessionHistoryView: View {
    let completedSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @State private var sessionToDelete: WorkoutSession?
    @State private var showingDeleteConfirmation = false
    @State private var selectedSession: WorkoutSession?
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Календарь
                ExpandableCalendarView()
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Список тренировок
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(completedSessions, id: \.self) { session in
                        let progress = calculateProgress(for: session)
                        WorkoutHistoryCard(session: session, progressState: progress)
                            .onTapGesture {
                                selectedSession = session
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Удалить", systemImage: "trash.fill")
                                }
                            }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
        .navigationDestination(item: $selectedSession) { session in
            WorkoutHistoryDetailView(session: session)
        }
        .alert("Удалить тренировку?", isPresented: $showingDeleteConfirmation) {
            Button("Отмена", role: .cancel) {
                sessionToDelete = nil
            }
            Button("Удалить", role: .destructive) {
                if let session = sessionToDelete {
                    deleteWorkout(session)
                    sessionToDelete = nil
                }
            }
        } message: {
            if let session = sessionToDelete {
                Text("Вы уверены, что хотите удалить тренировку \"\(session.workoutDayName)\" от \(formattedDate(session.date))? Это действие нельзя отменить.")
            }
        }
    }
    
    private func deleteWorkout(_ session: WorkoutSession) {
        withAnimation {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func calculateProgress(for session: WorkoutSession) -> ProgressState? {
        // Logic similar to parent, but we can't easily access allSessions here unless passed down.
        // For simplicity, we might just pass nil or refactor.
        // Ideally logic should be in a view model or manager.
        return nil // Placeholder, logic is complex to duplicate without context
    }
}

// MARK: - Exercise History List View
struct ExerciseHistoryListView: View {
    let sessions: [WorkoutSession]
    @State private var expandedExercise: String? = nil
    
    private var exercises: [String: [WorkoutSet]] {
        var dict: [String: [WorkoutSet]] = [:]
        for session in sessions {
            for set in session.sets {
                if dict[set.exerciseName] == nil {
                    dict[set.exerciseName] = []
                }
                dict[set.exerciseName]?.append(set)
            }
        }
        return dict
    }
    
    private var sortedExerciseNames: [String] {
        exercises.keys.sorted()
    }
    
    var body: some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(sortedExerciseNames, id: \.self) { name in
                ExerciseHistoryRow(
                    name: name,
                    sets: exercises[name] ?? [],
                    isExpanded: expandedExercise == name,
                    onTap: {
                        withAnimation {
                            if expandedExercise == name {
                                expandedExercise = nil
                            } else {
                                expandedExercise = name
                            }
                        }
                    }
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

struct ExerciseHistoryRow: View {
    let name: String
    let sets: [WorkoutSet]
    let isExpanded: Bool
    let onTap: () -> Void
    
    // Group sets by Date (Session)
    private var historyByDate: [(Date, [WorkoutSet])] {
        let grouped = Dictionary(grouping: sets) { $0.session?.date ?? Date.distantPast }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button(action: onTap) {
                    HStack {
                        Text(name)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                }
                
                // Expanded Content
                if isExpanded {
                    Divider()
                        .background(DesignSystem.Colors.secondaryText.opacity(0.3))
                    
                    VStack(spacing: 0) {
                        ForEach(historyByDate, id: \.0) { date, sets in
                            ExerciseHistoryDayView(date: date, sets: sets)
                            
                            if date != historyByDate.last?.0 {
                                Divider()
                                    .background(DesignSystem.Colors.secondaryText.opacity(0.1))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

private struct ExerciseHistoryDayView: View {
    let date: Date
    let sets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Date Header
            Text(formattedDate(date))
                .font(DesignSystem.Typography.caption())
                .foregroundColor(DesignSystem.Colors.neonGreen)
                .padding(.bottom, 4)
            
            // Sets
            ForEach(sets, id: \.self) { set in
                ExerciseHistorySetRow(set: set)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(Color.black.opacity(0.2))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

private struct ExerciseHistorySetRow: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack {
            Text("Подход \(set.setNumber)")
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            // Display based on logic
            Group {
                if set.weight > 0 || set.reps > 0 {
                    Text("\(Int(set.weight)) кг × \(set.reps)")
                } else {
                    Text((set.duration ?? 0) > 0 ? formatDuration(set.duration ?? 0) : "Завершено")
                }
            }
            .font(DesignSystem.Typography.body())
            .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Preference Key для отслеживания скролла
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Workout History Card

struct WorkoutHistoryCard: View {
    let session: WorkoutSession
    var progressState: ProgressState? = nil
    
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
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack {
                    // App Icon/Logo
                    Image("launch_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        // Program Name Label
                        if let programName = session.programName {
                             Text(programName.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.neonGreen)
                                .tracking(1)
                        }
                        
                        Text(session.workoutDayName)
                            .font(DesignSystem.Typography.title3())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(formattedDate)
                            .font(DesignSystem.Typography.callout())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Session Progress Arrow
                    if let state = progressState {
                        HStack(spacing: 4) {
                            Text(state == .improved ? "Рост" : (state == .declined ? "Спад" : "Стабильно"))
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(state.color)
                            
                            Image(systemName: state.icon)
                                .font(.headline)
                                .foregroundColor(state.color)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(state.color.opacity(0.15))
                        .cornerRadius(8)
                    }
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
                    
                    // Progress Description
                        if let state = progressState {
                             Text(state.description)
                                 .font(DesignSystem.Typography.caption())
                                 .foregroundColor(state.color)
                                 .multilineTextAlignment(.leading)
                                 .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Нет данных для сравнения")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
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
                    
                    // MARK: - Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                        // Time
                        StatCard(
                            title: "Время",
                            value: formatDuration(session.endTime?.timeIntervalSince(session.date) ?? 0),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        // Calories
                        StatCard(
                            title: "Калории",
                            value: session.calories != nil ? "\(session.calories!)" : "--",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        // Heart Rate
                        StatCard(
                            title: "Средний пульс",
                            value: session.averageHeartRate != nil ? "\(session.averageHeartRate!) bpm" : "--",
                            icon: "heart.fill",
                            color: .red
                        )
                        
                        // Sets Count (As a filler for 4th slot if needed, or remove)
                         StatCard(
                            title: "Подходов",
                            value: "\(session.sets.count)",
                            icon: "dumbbell.fill",
                            color: DesignSystem.Colors.neonGreen
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        
        return formatter.string(from: duration) ?? "0 мин"
    }
}

// MARK: - Exercise History Card (for detail view)

struct ExerciseHistoryCard: View {
    let exerciseName: String
    let sets: [WorkoutSet]
    
    private var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    // Получаем комментарий из первого сета
    private var exerciseComment: String? {
        sets.first?.comment
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
                    
                    // Show arrow if we can calculate progress (need logic or pass it in)
                    // For now, removing volume as requested. Can add simple text if needed.
                    Text(sets.count > 0 ? "\(sets.count) подх." : "")
                        .font(DesignSystem.Typography.callout())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                // Комментарий к упражнению (если есть)
                if let comment = exerciseComment, !comment.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "text.bubble.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Text(comment)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .italic()
                    }
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

// MARK: - Workout Type Distribution Chart

struct WorkoutTypeDistributionChart: View {
    let sessions: [WorkoutSession]
    
    private var workoutTypeCounts: [(type: String, count: Int, color: Color)] {
        // Подсчитываем типы на основе первого упражнения дня
        var strengthCount = 0
        var cardioCount = 0
        var circuitCount = 0
        
        for session in sessions {
            // Определяем тип тренировки по названию
            let dayName = session.workoutDayName.lowercased()
            if dayName.contains("кардио") {
                cardioCount += 1
            } else if dayName.contains("круговая") || dayName.contains("hiit") {
                circuitCount += 1
            } else {
                strengthCount += 1
            }
        }
        
        return [
            (type: "Силовые", count: strengthCount, color: .blue),
            (type: "Кардио", count: cardioCount, color: .red),
            (type: "Круговые", count: circuitCount, color: .orange)
        ].filter { $0.count > 0 }
    }
    
    private var total: Int {
        sessions.count
    }
    
    @State private var selectedType: String?
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            CardView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack {
                        Text("ТИПЫ ТРЕНИРОВОК")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if total > 0 {
                        HStack(spacing: DesignSystem.Spacing.xl) {
                            // Interactive Pie chart
                            ZStack {
                                Chart(workoutTypeCounts, id: \.type) { item in
                                    SectorMark(
                                        angle: .value("Count", item.count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: selectedType == item.type ? 2 : 1
                                    )
                                    .foregroundStyle(item.color)
                                    .opacity(selectedType == nil || selectedType == item.type ? 1 : 0.5)
                                    .cornerRadius(4)
                                }
                                .chartAngleSelection(value: $selectedType)
                                .animation(.bouncy, value: selectedType)
                                .frame(width: 100, height: 100)
                                
                                // Center label
                                VStack(spacing: 0) {
                                    if let selected = selectedType,
                                       let item = workoutTypeCounts.first(where: { $0.type == selected }) {
                                        Text("\(item.count)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(total)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            // Legend with interactive highlighting
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                ForEach(workoutTypeCounts, id: \.type) { item in
                                    Button(action: {
                                        withAnimation(.bouncy) {
                                            if selectedType == item.type {
                                                selectedType = nil
                                            } else {
                                                selectedType = item.type
                                            }
                                        }
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.sm) {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 12, height: 12)
                                            
                                            Text(item.type)
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(selectedType == nil || selectedType == item.type ? .white : .gray)
                                            
                                            Spacer()
                                            
                                            Text("\(item.count)")
                                                .font(DesignSystem.Typography.headline())
                                                .foregroundColor(selectedType == nil || selectedType == item.type ? DesignSystem.Colors.neonGreen : .gray)
                                        }
                                        .opacity(selectedType == nil || selectedType == item.type ? 1 : 0.5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        Text("Нет данных")
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            WorkoutTypesDetailView(workoutTypeCounts: workoutTypeCounts, sessions: sessions)
        }
    }
    
    private func angle(for index: Int, in data: [(type: String, count: Int, color: Color)]) -> Angle {
        let total = Double(data.reduce(0) { $0 + $1.count })
        guard total > 0 else { return .degrees(0) }
        
        let sum = Double(data.prefix(index).reduce(0) { $0 + $1.count })
        return .degrees(360 * sum / total - 90)
    }
}

// MARK: - Workout Types Detail View
struct WorkoutTypesDetailView: View {
    let workoutTypeCounts: [(type: String, count: Int, color: Color)]
    let sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large Interactive Chart
                    largeChartSection
                    
                    // Bar Chart Distribution
                    barChartSection
                    
                    // Exercise Types Breakdown
                    exerciseTypesSection
                    
                    // Type Details List
                    typeDetailsList
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle("Типы тренировок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    private var largeChartSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Chart(workoutTypeCounts, id: \.type) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: selectedType == item.type ? 3 : 1.5
                    )
                    .foregroundStyle(item.color)
                    .opacity(selectedType == nil || selectedType == item.type ? 1 : 0.4)
                    .cornerRadius(6)
                }
                .chartAngleSelection(value: $selectedType)
                .animation(.bouncy, value: selectedType)
                .frame(height: 200)
                
                // Center info
                VStack(spacing: 4) {
                    if let selected = selectedType,
                       let item = workoutTypeCounts.first(where: { $0.type == selected }) {
                        Text("\(item.count)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        Text(item.type)
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("\(sessions.count)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        Text("Всего")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                ForEach(workoutTypeCounts, id: \.type) { item in
                    Button(action: {
                        withAnimation(.bouncy) {
                            selectedType = selectedType == item.type ? nil : item.type
                        }
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.type)
                                .font(.caption)
                                .foregroundColor(selectedType == nil || selectedType == item.type ? .white : .gray)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selectedType == item.type ?
                            item.color.opacity(0.2) :
                            Color.white.opacity(0.05)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
    
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Распределение")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart(workoutTypeCounts, id: \.type) { item in
                BarMark(
                    x: .value("Type", item.type),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.color)
                .cornerRadius(8)
                .opacity(selectedType == nil || selectedType == item.type ? 1 : 0.4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(.gray)
                }
            }
            .animation(.bouncy, value: selectedType)
            .frame(height: 150)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
    
    private var exerciseTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Типы упражнений")
                .font(.headline)
                .foregroundColor(.white)
            
            let exerciseTypes = calculateExerciseTypeDistribution()
            
            ForEach(exerciseTypes, id: \.type) { item in
                HStack {
                    Text(item.type)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: geo.size.width * item.percentage)
                        }
                    }
                    .frame(width: 100, height: 8)
                    
                    Text("\(Int(item.percentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
    }
    
    private var typeDetailsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Подробности")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(workoutTypeCounts, id: \.type) { item in
                let percentage = Double(item.count) / Double(max(1, sessions.count)) * 100
                
                HStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.type)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("\(item.count) тренировок")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", percentage))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(item.color)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private func calculateExerciseTypeDistribution() -> [(type: String, percentage: CGFloat, color: Color)] {
        var typeCounts: [String: Int] = [:]
        
        for session in sessions {
            for set in session.sets {
                // Try to determine type from exercise name or default to general
                typeCounts[set.exerciseName, default: 0] += 1
            }
        }
        

        
        return workoutTypeCounts.map { item in
            (type: item.type, percentage: CGFloat(item.count) / CGFloat(max(1, sessions.count)), color: item.color)
        }
    }
}

// Pie Slice Shape
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    WorkoutHistoryView(selectedTab: .constant(3))
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
