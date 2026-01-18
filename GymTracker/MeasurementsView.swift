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
                        
                        // Сон (Sleep Card)
                        NavigationLink(destination: SleepGuideView()) {
                            SleepCard()
                        }
                        
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

extension MeasurementType: Identifiable {
    var id: String { self.rawValue }
}

#Preview {
    MeasurementsView()
        .modelContainer(for: [UserProfile.self, WeightRecord.self, BodyMeasurement.self], inMemory: true)
        .environmentObject(AuthManager())
}
