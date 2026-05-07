//
//  MeasurementsView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Charts
import HealthKit

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    

    @Binding var selectedTab: Int
    // Optimized Query: Only fetch completed sessions from DB, sorted by date
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse) 
    private var completedSessions: [WorkoutSession]
    
    @Query private var userProfiles: [UserProfile]
    
    @State private var showingSettings = false
    @State private var showingProgressHub = false

    private var workoutsThisWeekCount: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return completedSessions.filter { $0.date >= monday }.count
    }

    private var trainedDays: Set<Date> {
        Set(completedSessions.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // 1. Уровень / геймификация — всегда первый блок, независимо от наличия часов.
                        Button {
                            showingProgressHub = true
                        } label: {
                            AchievementsHubCard(
                                totalWorkouts: completedSessions.count,
                                workoutsThisWeek: workoutsThisWeekCount,
                                weeklyGoal: 4,
                                trainedDays: trainedDays,
                                lastWorkoutDate: completedSessions.first?.date
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // 2. История тренировок (hero card)
                        NavigationLink(destination: WorkoutHistoryView(selectedTab: $selectedTab)) {
                            HistoryHeroCard(
                                sessions: completedSessions,
                                totalCompletedCount: completedSessions.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // 3. Кольца активности — авто-скрываются если Apple Watch выключены или нет данных.
                        ActivityRingsSection()
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        // 4. Apple Health — единый блок: активность + восстановление (сон, пульс, энергия)
                        HealthStatsCard(lastWorkoutSession: completedSessions.first)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Weight Tracker
                        WeightTrackerCard()
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Замеры тела
                        NavigationLink(destination: BodyMeasurementsView()) {
                            BodyMeasurementsRowCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationTitle(Text("Статистика".localized()))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileButton {
                         showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingProgressHub) {
                ProgressHubView()
            }
        }
    }
    
    // Helper helper
    // Helper helper
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Heart Rate Stats Card


extension MeasurementType: Identifiable {
    var id: String { self.rawValue }
}

// MARK: - Body Measurements Row Card

private struct BodyMeasurementsRowCard: View {
    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    private var trackedTypes: [MeasurementType] {
        var seen = Set<MeasurementType>()
        var ordered: [MeasurementType] = []
        for m in measurements where !seen.contains(m.type) {
            seen.insert(m.type)
            ordered.append(m.type)
        }
        return ordered
    }

    private var subtitle: String {
        let count = trackedTypes.count
        if count == 0 {
            return "Запиши первый замер".localized()
        }
        if let lastDate = measurements.first?.date {
            let formatter = DateFormatter()
            formatter.locale = LanguageManager.shared.currentLocale
            formatter.dateFormat = "d MMM"
            let dateStr = formatter.string(from: lastDate)
            return String(format: "%d %@ · %@",
                          count,
                          pluralForm(count: count),
                          dateStr)
        }
        return String(format: "%d %@", count, pluralForm(count: count))
    }

    private func pluralForm(count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 { return "показатель".localized() }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "показателя".localized() }
        return "показателей".localized()
    }

    private let dotColors: [Color] = [
        DesignSystem.Colors.neonGreen,
        Color.cyan,
        Color.orange,
        DesignSystem.Colors.accentPurple
    ]

    var body: some View {
        HStack(spacing: 14) {
            iconTile

            VStack(alignment: .leading, spacing: 4) {
                Text("Замеры тела".localized())
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer(minLength: 8)

            if !trackedTypes.isEmpty {
                trackedDots
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }

    private var cardBackground: some View {
        ZStack {
            Color(white: 0.07)

            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.0, y: 0.5),
                startRadius: 0,
                endRadius: 200
            )
        }
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.28),
                            DesignSystem.Colors.neonGreen.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(DesignSystem.Colors.neonGreen.opacity(0.32), lineWidth: 0.5)
                .frame(width: 48, height: 48)

            Image(systemName: "ruler.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.neonGreen)
                .rotationEffect(.degrees(-25))
        }
    }

    private var trackedDots: some View {
        let visible = Array(trackedTypes.prefix(4))
        return HStack(spacing: -6) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { idx, _ in
                Circle()
                    .fill(dotColors[idx % dotColors.count])
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().strokeBorder(Color(white: 0.07), lineWidth: 2)
                    )
            }

            if trackedTypes.count > visible.count {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().strokeBorder(Color(white: 0.07), lineWidth: 2)
                        )
                    Text("+\(trackedTypes.count - visible.count)")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }
}

#Preview {
    MeasurementsView(selectedTab: .constant(3))
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
        .environmentObject(AuthManager())
}
