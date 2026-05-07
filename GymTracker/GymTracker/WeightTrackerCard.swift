//
//  WeightTrackerCard.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData

struct WeightTrackerCard: View {
    @Query private var userProfiles: [UserProfile]
    @State private var showingAddWeight = false
    @State private var showingProfile = false
    @State private var isHistoryExpanded = false

    private var currentProfile: UserProfile? {
        userProfiles.first
    }

    private var weightHistory: [WeightRecord] {
        currentProfile?.weightHistory.sorted { $0.date > $1.date } ?? []
    }

    private var currentWeight: Double {
        weightHistory.first?.weight ?? 0
    }

    private var weightDelta: Double? {
        guard weightHistory.count >= 2, currentWeight > 0 else { return nil }
        let prev = weightHistory[1].weight
        let diff = currentWeight - prev
        return abs(diff) > 0.05 ? diff : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                weightSection
                verticalDivider
                heightSection
            }

            if isHistoryExpanded && weightHistory.count > 1 {
                historyList
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
        .sheet(isPresented: $showingAddWeight) {
            if let profile = currentProfile {
                AddWeightView(userProfile: profile)
            } else {
                CreateProfileView()
            }
        }
        .sheet(isPresented: $showingProfile) {
            if let profile = currentProfile {
                EditHeightView(userProfile: profile)
                    .presentationDetents([.height(250)])
            } else {
                CreateProfileView()
            }
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            Color(white: 0.07)

            RadialGradient(
                colors: [DesignSystem.Colors.neonGreen.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.0, y: 0.0),
                startRadius: 0,
                endRadius: 240
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.07), Color.clear],
                center: UnitPoint(x: 1.0, y: 1.0),
                startRadius: 0,
                endRadius: 220
            )
        }
    }

    // MARK: - Divider

    private var verticalDivider: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.14),
                Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: 1)
        .padding(.vertical, 22)
    }

    // MARK: - Weight section

    private var weightSection: some View {
        Button(action: { showingAddWeight = true }) {
            VStack(alignment: .leading, spacing: 12) {
                metricHeader(
                    icon: "scalemass.fill",
                    label: "Вес".localized(),
                    tint: DesignSystem.Colors.neonGreen
                )

                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(currentWeight > 0 ? String(format: "%.1f", currentWeight) : "—")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(value: currentWeight))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if currentWeight > 0 {
                        Text("кг".localized())
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.bottom, 3)
                    }
                }

                weightFooter
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    @ViewBuilder
    private var weightFooter: some View {
        if let delta = weightDelta {
            let isLoss = delta < 0
            let tint = isLoss ? DesignSystem.Colors.neonGreen : Color.orange

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isHistoryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isLoss ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 10, weight: .heavy))
                    Text(String(format: "%.1f кг", abs(delta)))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .heavy))
                        .opacity(0.6)
                        .rotationEffect(.degrees(isHistoryExpanded ? 180 : 0))
                }
                .foregroundStyle(tint)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(tint.opacity(0.14))
                )
                .overlay(
                    Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        } else if weightHistory.count > 1 {
            historyToggle
        } else {
            Text(currentWeight > 0 ? "Стабильный вес".localized() : "Запишите первый замер".localized())
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var historyToggle: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isHistoryExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text("История".localized())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .heavy))
                    .rotationEffect(.degrees(isHistoryExpanded ? 180 : 0))
            }
            .foregroundStyle(.white.opacity(0.45))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Height section

    private var heightSection: some View {
        Button(action: { showingProfile = true }) {
            VStack(alignment: .leading, spacing: 12) {
                metricHeader(
                    icon: "ruler.fill",
                    label: "Рост".localized(),
                    tint: Color.cyan
                )

                if let profile = currentProfile, profile.height > 0 {
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text("\(Int(profile.height))")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        Text("см".localized())
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.bottom, 3)
                    }
                } else {
                    Text("Указать".localized())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }

                editHeightChip
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
    }

    private var editHeightChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "pencil")
                .font(.system(size: 10, weight: .heavy))
            Text("Изменить".localized())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color.white.opacity(0.06))
        )
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Reusable header

    private func metricHeader(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 30, height: 30)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(tint.opacity(0.30), lineWidth: 0.5)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(label.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    // MARK: - History list

    private var historyList: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(spacing: 0) {
                ForEach(Array(weightHistory.dropFirst().prefix(5)), id: \.date) { record in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 5, height: 5)

                        Text(formatDate(record.date))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()

                        Text(String(format: "%.1f кг", record.weight))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                }
            }
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.25))
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Pressable style

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
