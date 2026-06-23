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
    @AppStorage("seenTourVersion") private var seenTourVersion = 0
    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled = true
    @ObservedObject private var tour = TourManager.shared

    var body: some View {
        // Native TabView — on iOS 26 the system bar is Liquid Glass and content
        // scrolls behind it. A custom bar can't reproduce that (nothing renders
        // behind a safeAreaInset bar, so glass has nothing to refract). The tour
        // spotlights the bar by arithmetic, which still matches the native bar:
        // full width, 49pt content band sitting above the home indicator.
        TabView(selection: $selectedTab) {
            WorkoutView(modelContext: modelContext, selectedTab: $selectedTab)
                .tag(0)
                .tabItem {
                    Label("Тренировка".localized(), systemImage: "figure.strengthtraining.traditional")
                }
                .accessibilityIdentifier("tab_workout")

            ProgramView()
                .tag(1)
                .tabItem {
                    Label("Программа".localized(), systemImage: "list.bullet.clipboard.fill")
                }
                .accessibilityIdentifier("tab_program")

            ReferenceView()
                .tag(2)
                .tabItem {
                    Label("Справочник".localized(), systemImage: "book.fill")
                }
                .accessibilityIdentifier("tab_reference")

            MeasurementsView(selectedTab: $selectedTab)
                .tag(3)
                .tabItem {
                    Label("Статистика".localized(), systemImage: "chart.line.uptrend.xyaxis")
                }
                .accessibilityIdentifier("tab_stats")
        }
        .tint(DesignSystem.Colors.accent)
        .accessibilityIdentifier("main_tab_bar")
        .overlayPreferenceValue(TourAnchorsKey.self) { anchors in
            GeometryReader { proxy in
                TourOverlay(tour: tour, anchors: anchors, proxy: proxy)
            }
            .ignoresSafeArea()
            .allowsHitTesting(tour.isActive)
        }
        .onChange(of: tour.index) { _, _ in syncTourTab() }
        .onChange(of: tour.isActive) { _, active in if active { syncTourTab() } }
        .onAppear {
            tour.onFinish = { seenTourVersion = TourManager.version }
            guard seenTourVersion < TourManager.version else { return }
            // Let the UI settle (and the splash dismiss) before starting.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                guard seenTourVersion < TourManager.version, !tour.isActive else { return }
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
