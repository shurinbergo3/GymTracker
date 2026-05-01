//
//  ActivityRingsSection.swift
//  GymTracker
//
//  Smart Apple Watch / Activity Rings section. Auto-hides when:
//   • the user has disabled "Connect Apple Watch" in Settings, or
//   • HealthKit returned no data (no Watch / no rings).
//

import SwiftUI

struct ActivityRingsSection: View {
    @AppStorage("isAppleWatchEnabled") private var isAppleWatchEnabled = true
    @State private var hasData: Bool? = nil

    var body: some View {
        Group {
            if isAppleWatchEnabled, hasData == true {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Label("КОЛЬЦА АКТИВНОСТИ".localized(), systemImage: "applewatch")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                        .tracking(2)

                    ActivityRingsCard()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .task {
            await detect()
        }
        .onChange(of: isAppleWatchEnabled) { _, newValue in
            if newValue {
                Task { await detect(force: true) }
            } else {
                hasData = false
            }
        }
    }

    private func detect(force: Bool = false) async {
        if !force, hasData != nil { return }
        guard isAppleWatchEnabled else {
            await MainActor.run { self.hasData = false }
            return
        }
        guard HealthManager.shared.isAuthorized else {
            await MainActor.run { self.hasData = false }
            return
        }

        let summary = await HealthManager.shared.fetchActivitySummary()
        let any = (summary.map { s in
            s.activeEnergyBurned.doubleValue(for: .kilocalorie()) > 1
                || s.appleStandHours.doubleValue(for: .count()) > 0
                || s.appleExerciseTime.doubleValue(for: .minute()) > 0
        }) ?? false

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.hasData = any
            }
        }
    }
}
