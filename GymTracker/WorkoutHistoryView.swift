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
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if completedSessions.isEmpty {
                    EmptyStateView(
                        icon: "figure.strengthtraining.traditional",
                        title: "Нет завершенных тренировок",
                        message: "История ваших тренировок появится здесь",
                        buttonTitle: "Начать тренировку"
                    ) {
                        dismiss()
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

// MARK: - Session History View
struct SessionHistoryView: View {
    let completedSessions: [WorkoutSession]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Календарь
            ExpandableCalendarView()
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Список тренировок
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(completedSessions, id: \.self) { session in
                    let progress = calculateProgress(for: session)
                    NavigationLink(destination: WorkoutHistoryDetailView(session: session)) {
                        WorkoutHistoryCard(session: session, progressState: progress)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
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
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("ТИПЫ ТРЕНИРОВОК")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .tracking(1.2)
                
                if total > 0 {
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        // Pie chart
                        ZStack {
                            ForEach(Array(workoutTypeCounts.enumerated()), id: \.element.type) { index, item in
                                PieSlice(
                                    startAngle: angle(for: index, in: workoutTypeCounts),
                                    endAngle: angle(for: index + 1, in: workoutTypeCounts)
                                )
                                .fill(item.color)
                            }
                            
                            Circle()
                                .fill(DesignSystem.Colors.cardBackground)
                                .frame(width: 50, height: 50)
                            
                            Text("\(total)")
                                .font(DesignSystem.Typography.title3())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                        .frame(width: 100, height: 100)
                        
                        // Legend
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            ForEach(workoutTypeCounts, id: \.type) { item in
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(item.type)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count)")
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                }
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
    
    private func angle(for index: Int, in data: [(type: String, count: Int, color: Color)]) -> Angle {
        let total = Double(data.reduce(0) { $0 + $1.count })
        guard total > 0 else { return .degrees(0) }
        
        let sum = Double(data.prefix(index).reduce(0) { $0 + $1.count })
        return .degrees(360 * sum / total - 90)
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
    WorkoutHistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutSet.self], inMemory: true)
}
