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
        // Авторизацию HealthKit НЕ запрашиваем здесь — это вызывает системный
        // алерт сразу при первом рендере дашборда и создаёт ощущение зависания.
        // Запрос идёт из WorkoutView.task при первом открытии вкладки тренировки.
    }
}
