//
//  WatchBenefitsInfo.swift
//  GymTracker
//
//  Single source of truth for "what an Apple Watch unlocks" — the recovery
//  signals BODY FORGE can only read from the watch. Reused in onboarding
//  (the "Есть Apple Watch?" step) and in Settings (info under the watch toggle)
//  so the promise stays consistent everywhere.
//

import SwiftUI

struct WatchBenefit: Identifiable {
    let id = UUID()
    let icon: String
    let title: String   // localization key (Russian source)
    let tint: Color

    static let all: [WatchBenefit] = [
        WatchBenefit(icon: "waveform.path.ecg", title: "Уровень стресса",
                     tint: Color(red: 1.0, green: 0.45, blue: 0.55)),
        WatchBenefit(icon: "waveform", title: "Вариабельность пульса",
                     tint: Color(red: 0.55, green: 0.85, blue: 1.0)),
        WatchBenefit(icon: "heart.fill", title: "Пульс покоя",
                     tint: Color(red: 1.0, green: 0.35, blue: 0.45)),
        WatchBenefit(icon: "lungs.fill", title: "Дыхание во сне",
                     tint: Color(red: 0.45, green: 0.8, blue: 0.95)),
        WatchBenefit(icon: "flame.fill", title: "Кольца активности и калории",
                     tint: Color(red: 1.0, green: 0.6, blue: 0.2))
    ]
}

/// Compact list of watch-only metrics. Visual host (card/background) is the
/// caller's responsibility so it blends into both onboarding and settings.
struct WatchBenefitsList: View {
    var spacing: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(WatchBenefit.all) { benefit in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(benefit.tint.opacity(0.16))
                            .frame(width: 30, height: 30)
                        Image(systemName: benefit.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(benefit.tint)
                    }
                    Text(benefit.title.localized())
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
            }

            // These signals also feed the AI coach, not just the charts.
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accentPurple.opacity(0.16))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.accentPurple)
                }
                Text("Эти показатели анализирует и ИИ-тренер - и подстраивает под них рекомендации.".localized())
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }
}
