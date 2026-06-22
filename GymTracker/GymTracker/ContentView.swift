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
    @AppStorage("hasSeenTour") private var hasSeenTour = false
    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled = true
    @ObservedObject private var tour = TourManager.shared

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
        .overlayPreferenceValue(TourAnchorsKey.self) { anchors in
            GeometryReader { proxy in
                TourOverlay(tour: tour, anchors: anchors, proxy: proxy)
            }
            .allowsHitTesting(tour.isActive)
        }
        .onChange(of: tour.index) { _, _ in syncTourTab() }
        .onChange(of: tour.isActive) { _, active in if active { syncTourTab() } }
        .onAppear {
            tour.onFinish = { hasSeenTour = true }
            guard !hasSeenTour else { return }
            // Let the UI settle (and the splash dismiss) before starting.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                guard !hasSeenTour, !tour.isActive else { return }
                tour.start(TourSteps.make(hasWatch: isAppleWatchEnabled))
            }
        }
    }

    /// Drive the tab selection from the active tour step.
    private func syncTourTab() {
        guard tour.isActive, let tab = tour.current?.tab, tab != selectedTab else { return }
        withAnimation(.easeInOut(duration: 0.3)) { selectedTab = tab }
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
