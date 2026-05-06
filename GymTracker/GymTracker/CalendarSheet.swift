//
//  CalendarSheet.swift
//  GymTracker
//
//  Sheet wrapper around the workout calendar — opened from the
//  Weekly Streak Strip on the dashboard.
//

import SwiftUI
import SwiftData

struct CalendarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @State private var externalWorkouts: [ExternalWorkout] = []
    @State private var showingAppleHealthSheet = false

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }

    private var trainedDays: Set<Date> {
        let cal = Calendar.current
        return Set(completedSessions.map { cal.startOfDay(for: $0.date) })
    }

    private var externalOnlyDays: Set<Date> {
        let cal = Calendar.current
        return Set(externalWorkouts.map { cal.startOfDay(for: $0.startDate) })
            .subtracting(trainedDays)
    }

    private var workoutsThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        return completedSessions.filter { $0.date >= monthStart }.count
    }

    private var externalThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        return externalWorkouts.filter { $0.startDate >= monthStart }.count
    }

    private var activeDaysThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return 0 }
        let appDays = completedSessions
            .filter { $0.date >= monthStart }
            .map { cal.startOfDay(for: $0.date) }
        let extDays = externalWorkouts
            .filter { $0.startDate >= monthStart }
            .map { cal.startOfDay(for: $0.startDate) }
        return Set(appDays + extDays).count
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        // Streak считаем по любой активности (своей или из Apple Health) —
        // так пользователю проще удержать серию, не пропуская кардио-дни.
        let activeDays = trainedDays.union(externalOnlyDays)
        var current = cal.startOfDay(for: Date())
        var count = 0
        if !activeDays.contains(current) {
            guard let y = cal.date(byAdding: .day, value: -1, to: current) else { return 0 }
            current = y
        }
        while activeDays.contains(current) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        statsRow
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.top, DesignSystem.Spacing.md)

                        ExpandableCalendarView(
                            lockedExpanded: true,
                            externalWorkoutDays: externalOnlyDays
                        )
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        if !externalWorkouts.isEmpty {
                            Button { showingAppleHealthSheet = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.pink)
                                    Text(String(format: "Apple Health: %d тренировок".localized(), externalWorkouts.count))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DesignSystem.Colors.primaryText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.pink.opacity(0.10))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.pink.opacity(0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }

                        legend
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        Spacer().frame(height: 60)
                    }
                }
            }
            .task {
                let end = Date()
                guard let start = Calendar.current.date(byAdding: .day, value: -90, to: end) else { return }
                let fetched = await HealthManager.shared.fetchExternalWorkouts(from: start, to: end)
                await MainActor.run { self.externalWorkouts = fetched }
            }
            .sheet(isPresented: $showingAppleHealthSheet) {
                AppleHealthWorkoutsSheet(workouts: externalWorkouts)
            }
            .navigationTitle("Календарь тренировок".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: { dismiss() })
                }
            }
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            statTile(
                icon: "dumbbell.fill",
                value: "\(workoutsThisMonth)",
                label: String(localized: "calendar_workouts_count_label"),
                tint: DesignSystem.Colors.neonGreen
            )
            statTile(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: String(localized: "Серия"),
                tint: .orange
            )
            statTile(
                icon: "calendar",
                value: "\(activeDaysThisMonth)",
                label: String(localized: "Активных дней"),
                tint: DesignSystem.Colors.accentPurple
            )
        }
    }

    private func statTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(icon: "dumbbell.fill", color: DesignSystem.Colors.neonGreen, text: String(localized: "Тренировка"))
            legendItem(icon: "heart.fill", color: Color.pink, text: "Apple Health")
            legendItem(icon: "figure.mind.and.body", color: DesignSystem.Colors.secondaryText.opacity(0.6), text: String(localized: "Отдых"))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func legendItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
    }
}

#Preview {
    CalendarSheet()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
