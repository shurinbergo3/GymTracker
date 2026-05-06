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

    var body: some View {
        Group {
            // Показываем всегда, пока пользователь не выключил Apple Watch в настройках.
            // Если HealthKit ещё не авторизован или нет данных за день — нативный
            // HKActivityRingView сам покажет пустые кольца, что лучше чем пропадание блока.
            if isAppleWatchEnabled {
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
            // Прогреваем авторизацию HealthKit, если её ещё нет —
            // тогда кольца сразу подтянут данные без пере-открытия экрана.
            if !HealthManager.shared.isAuthorized {
                _ = await HealthManager.shared.requestAuthorization()
            }
        }
    }
}
