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
    
    var body: some View {
        TabView {
            // Tab 1: Тренировка
            WorkoutView(modelContext: modelContext)
                .tabItem {
                    Label("Тренировка", systemImage: "figure.strengthtraining.traditional")
                }
            
            // Tab 2: Программа
            ProgramView()
                .tabItem {
                    Label("Программа", systemImage: "list.bullet.clipboard.fill")
                }
            
            // Tab 3: Параметры
            MeasurementsView()
                .tabItem {
                    Label("Параметры", systemImage: "chart.line.uptrend.xyaxis")
                }
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
