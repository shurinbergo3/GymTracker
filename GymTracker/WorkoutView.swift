//
//  WorkoutView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var workoutManager: WorkoutManager
    @Query(filter: #Predicate<Program> { $0.isActive == true })
    private var activePrograms: [Program]
    
    init(modelContext: ModelContext) {
        _workoutManager = StateObject(wrappedValue: WorkoutManager(modelContext: modelContext))
    }
    
    private var activeProgram: Program? {
        activePrograms.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if activeProgram == nil {
                    // Empty State
                    EmptyStateView(
                        icon: "figure.strengthtraining.traditional",
                        title: "Нет активной программы",
                        message: "Создайте программу тренировок, чтобы начать отслеживать свой прогресс",
                        buttonTitle: "Создать программу"
                    ) {
                        // TODO: Открыть экран создания программы
                    }
                } else {
                    // State-based content
                    switch workoutManager.workoutState {
                    case .idle:
                        DashboardView()
                            .environmentObject(workoutManager)
                    case .active:
                        ActiveWorkoutView()
                            .environmentObject(workoutManager)
                    case .summary:
                        SummaryOverlay()
                            .environmentObject(workoutManager)
                    }
                }
            }
            .navigationTitle("Тренировка")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if workoutManager.activeProgram == nil {
                workoutManager.loadActiveProgram()
                workoutManager.initializeSelectedDay()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Program.self, WorkoutDay.self, WorkoutSession.self, configurations: config)
    
    return WorkoutView(modelContext: container.mainContext)
        .modelContainer(container)
}
