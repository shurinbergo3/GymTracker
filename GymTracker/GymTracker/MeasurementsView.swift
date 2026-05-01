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

    private var workoutsThisWeekCount: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else { return 0 }
        return completedSessions.filter { $0.date >= monday }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // График прогресса
                        if !completedSessions.isEmpty {
                            WorkoutProgressChart(sessions: completedSessions)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }

                        // История тренировок (hero card)
                        NavigationLink(destination: WorkoutHistoryView(selectedTab: $selectedTab)) {
                            HistoryHeroCard(
                                sessions: completedSessions,
                                totalCompletedCount: completedSessions.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Активность — кольца Apple Watch ИЛИ ачивки (если часов нет)
                        ActivityHeroSection(
                            totalWorkouts: completedSessions.count,
                            workoutsThisWeek: workoutsThisWeekCount
                        )
                        .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Apple Health — единый блок: активность + восстановление (сон, пульс, энергия)
                        HealthStatsCard(lastWorkoutSession: completedSessions.first)
                            .padding(.horizontal, DesignSystem.Spacing.lg)

                        // Weight Tracker
                        WeightTrackerCard()
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Замеры тела
                        NavigationLink(destination: BodyMeasurementsView()) {
                            CardView {
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .font(.title2)
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                        .frame(width: 40, height: 40)
                                        .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text("Замеры тела".localized())
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding()
                            }
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

#Preview {
    MeasurementsView(selectedTab: .constant(3))
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
        .environmentObject(AuthManager())
}
