//
//  MeasurementsView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct MeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    

    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    

    
    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.isCompleted }
    }
    

    

    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        
                        // SECTION 1: STATISTICS OVERVIEW
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            
                            // Активность (Activity Rings)
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("АКТИВНОСТЬ")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .tracking(1.2)
                                    
                                    HStack {
                                        Spacer()
                                        ActivityRingsView()
                                            .frame(width: 150, height: 150)
                                        Spacer()
                                    }
                                }
                                .padding(DesignSystem.Spacing.lg)
                            }
                            
                            // История Тренировок (Кнопка)
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
                            
                            // График прогресса
                            if !completedSessions.isEmpty {
                                WorkoutProgressChart(sessions: completedSessions) // Now height 120
                                
                                // Диаграмма типов
                                WorkoutTypeDistributionChart(sessions: completedSessions)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // SECTION 2: BODY MEASUREMENTS
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("ЗАМЕРЫ ТЕЛА")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            // Navigation Link to Body Measurements
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
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileButton {
                         // Settings handled by parent in WorkoutView, but here we might need to handle it differently
                         // Actually UserProfileButton takes an action.
                         // But MeasurementsView is a configured tab.
                         // We probably don't need settings here or should route to settings.
                    }
                }
            }
        }
    }
    
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
