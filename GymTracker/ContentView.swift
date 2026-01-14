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
                    Label("Тренировка", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)
            
            // Tab 2: Программа
            ProgramView()
                .tabItem {
                    Label("Программа", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            
            // Tab 3: Параметры
            MeasurementsView()
                .tabItem {
                    Label("Параметры", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .tint(DesignSystem.Colors.accent)
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
