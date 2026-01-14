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
                        
                        // SECTION 1: BODY MEASUREMENTS
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
                        
                        // SECTION 2: WORKOUT HISTORY
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("ИСТОРИЯ ТРЕНИРОВОК")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .tracking(1.2)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                            if completedSessions.isEmpty {
                                Text("История пуста")
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            } else {
                                LazyVStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(completedSessions, id: \.self) { session in
                                        NavigationLink(destination: WorkoutHistoryDetailView(session: session)) {
                                            WorkoutHistoryCard(session: session)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileButton()
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
