//
//  ContentView.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Тренировка
            WorkoutView(modelContext: modelContext, selectedTab: $selectedTab)
                .tabItem {
                    Label("Тренировка".localized(), systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)
                .accessibilityIdentifier("tab_workout")
            
            // Tab 2: Программа
            ProgramView()
                .tabItem {
                    Label("Программа".localized(), systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
                .accessibilityIdentifier("tab_program")
            
            // Tab 3: Справочник
            ReferenceView()
                .tabItem {
                    Label("Справочник".localized(), systemImage: "book.fill")
                }
                .tag(2)
                .accessibilityIdentifier("tab_reference")
            
            // Tab 4: Параметры
            MeasurementsView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Статистика".localized(), systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
                .accessibilityIdentifier("tab_stats")
            

        }
        .tint(DesignSystem.Colors.accent)
        .accessibilityIdentifier("main_tab_bar")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            BodyMeasurement.self,
            Program.self,
            WorkoutDay.self,
            ExerciseTemplate.self,
            WorkoutSession.self,
            WorkoutSet.self
        ], inMemory: true)
}
