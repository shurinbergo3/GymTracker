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
    

    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    

    
    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }
    

    

    
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Активность (Activity Rings)
                        ActivityRingsCard()
                        
                        NavigationLink(destination: SleepGuideView()) {
                            SleepCard()
                        }
                        
                        // Пульс (New Card)
                        HeartRateStatsCard(lastWorkoutSession: completedSessions.first)
                        
                        // Замеры тела (Swapped position)
                        NavigationLink(destination: BodyMeasurementsView()) {
                            CardView {
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .font(.title2)
                                        .foregroundColor(DesignSystem.Colors.neonGreen)
                                        .frame(width: 40, height: 40)
                                        .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text("Замеры тела")
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding()
                            }
                        }
                        
                        // График прогресса
                        if !completedSessions.isEmpty {
                            WorkoutProgressChart(sessions: completedSessions)
                            
                            // Диаграмма типов
                            WorkoutTypeDistributionChart(sessions: completedSessions)
                        }
                        
                        // История Тренировок (Moved to bottom)
                        NavigationLink(destination: WorkoutHistoryView()) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                    .foregroundColor(DesignSystem.Colors.neonGreen)
                                    .frame(width: 40, height: 40)
                                    .background(DesignSystem.Colors.neonGreen.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("История тренировок")
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    if let last = completedSessions.first {
                                        Text("Последняя: \(formattedDate(last.date))")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    } else {
                                        Text("Нет записей")
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.large)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Статистика")
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
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Heart Rate Stats Card
struct HeartRateStatsCard: View {
    let lastWorkoutSession: WorkoutSession?
    @State private var restingHR: Int = 0
    
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Пульс")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if HealthManager.shared.isAuthorized {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.neonGreen)
                    }
                }
                
                HStack(spacing: 20) {
                    // Resting HR
                    VStack(alignment: .leading, spacing: 4) {
                        Text("В покое")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(restingHR > 0 ? "\(restingHR)" : "--")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            Text("уд/мин")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Workout HR
                    VStack(alignment: .leading, spacing: 4) {
                        Text("На тренировке")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            if let session = lastWorkoutSession, let avg = session.averageHeartRate, avg > 0 {
                                Text("\(avg)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("--")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text("уд/мин")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .task {
            if HealthManager.shared.isAuthorized {
                let hr = await HealthManager.shared.fetchRestingHeartRate()
                await MainActor.run {
                    self.restingHR = Int(hr)
                }
            }
        }
    }
}

extension MeasurementType: Identifiable {
    var id: String { self.rawValue }
}

#Preview {
    MeasurementsView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
        .environmentObject(AuthManager())
}
