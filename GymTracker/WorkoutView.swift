//
//  WorkoutView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

@MainActor
struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var workoutManager: WorkoutManager
    @Query(filter: #Predicate<Program> { $0.isActive == true })
    private var activePrograms: [Program]
    
    @Binding var selectedTab: Int
    
    @State private var showingSettings = false
    
    init(modelContext: ModelContext, selectedTab: Binding<Int>) {
        _workoutManager = StateObject(wrappedValue: WorkoutManager(
            modelContext: modelContext,
            healthProvider: HealthManager.shared,
            activityProvider: LiveActivityManager.shared
        ))
        _selectedTab = selectedTab
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
                        title: String(localized: "no_active_program_title"),
                        message: String(localized: "no_active_program_message"),
                        buttonTitle: String(localized: "set_program_button")
                    ) {
                        selectedTab = 1 // Switch to Program tab
                    }
                } else {
                    // State-based content
                    switch workoutManager.workoutState {
                    case .idle:
                        DashboardView() // settings handled by parent toolbar now
                            .environmentObject(workoutManager)
                    case .countdown:
                        CountdownView {
                            workoutManager.beginActiveSession()
                        }
                    case .active:
                        ActiveWorkoutView()
                            .environmentObject(workoutManager)
                    case .summary:
                        SummaryOverlay()
                            .environmentObject(workoutManager)
                    }
                }
            }
            .navigationTitle(Text("app_title"))
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
            }
        }

        .onAppear {
            if workoutManager.activeProgram == nil {
                workoutManager.loadActiveProgram()
                workoutManager.initializeSelectedDay()
            }
        }
        .task {
            // Optimization: Only request if not authorized (prevents onAppear loops)
            if !HealthManager.shared.isAuthorized {
                workoutManager.requestHealthAccess()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Program.self, WorkoutDay.self, WorkoutSession.self, configurations: config)
    
    return WorkoutView(modelContext: container.mainContext, selectedTab: .constant(0))
        .modelContainer(container)
}
