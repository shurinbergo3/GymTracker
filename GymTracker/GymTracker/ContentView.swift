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
        // Native TabView drives content paging + per-tab state; its own bar is
        // hidden and replaced by a custom bar so the tour can anchor each button
        // exactly (the system UITabBar exposes no per-item frame).
        TabView(selection: $selectedTab) {
            WorkoutView(modelContext: modelContext, selectedTab: $selectedTab)
                .tag(0)
                .toolbar(.hidden, for: .tabBar)

            ProgramView()
                .tag(1)
                .toolbar(.hidden, for: .tabBar)

            ReferenceView()
                .tag(2)
                .toolbar(.hidden, for: .tabBar)

            MeasurementsView(selectedTab: $selectedTab)
                .tag(3)
                .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TourTabBar(selectedTab: $selectedTab)
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

// MARK: - Custom bottom bar

/// Replaces the system tab bar so each button is a real, anchorable view —
/// lets the coach-mark tour spotlight a single tab pixel-accurately.
private struct TourTabBar: View {
    @Binding var selectedTab: Int

    private struct Item {
        let icon: String
        let label: String
        let tag: Int
        let id: String
    }

    private let items: [Item] = [
        Item(icon: "figure.strengthtraining.traditional", label: "Тренировка", tag: 0, id: "tab_workout"),
        Item(icon: "list.bullet.clipboard.fill", label: "Программа", tag: 1, id: "tab_program"),
        Item(icon: "book.fill", label: "Справочник", tag: 2, id: "tab_reference"),
        Item(icon: "chart.line.uptrend.xyaxis", label: "Статистика", tag: 3, id: "tab_stats")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                let isActive = selectedTab == item.tag
                Button {
                    if selectedTab != item.tag {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = item.tag }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: .semibold))
                        Text(item.label.localized())
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(isActive ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 49)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(item.id)
            }
        }
        .padding(.top, 6)
        .background(barBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    /// On iOS 26 the bar rides on real Liquid Glass; older systems fall back to a
    /// plain translucent material. The previous build stacked an opaque dark layer
    /// over the material, which flattened the bar into solid black and killed the
    /// glass entirely.
    @ViewBuilder
    private var barBackground: some View {
        if #available(iOS 26.0, *) {
            Rectangle()
                .fill(Color.clear)
                .glassEffect(.regular, in: Rectangle())
                .ignoresSafeArea(edges: .bottom)
        } else {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
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
