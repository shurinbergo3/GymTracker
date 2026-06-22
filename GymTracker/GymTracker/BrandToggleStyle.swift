//
//  BrandToggleStyle.swift
//  GymTracker
//
//  Single toggle style used across the app. The stock switch put a white knob
//  on the bright neon track, where it visually blended in. This uses the
//  brand's "dark-on-neon" language (same as the primary buttons): neon track
//  with a dark knob when on, gray track with a white knob when off — clear in
//  both states.
//

import SwiftUI

struct BrandToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            switchTrack(isOn: configuration.isOn)
                .contentShape(Capsule())
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
                .accessibilityAddTraits(.isButton)
        }
    }

    private func switchTrack(isOn: Bool) -> some View {
        let width: CGFloat = 51, height: CGFloat = 31, knob: CGFloat = 25
        return ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? DesignSystem.Colors.neonGreen : Color.white.opacity(0.16))

            Circle()
                .fill(isOn ? Color.black.opacity(0.85) : Color.white)
                .frame(width: knob, height: knob)
                .padding(3)
                .shadow(color: .black.opacity(0.22), radius: 1.5, x: 0, y: 1)
        }
        .frame(width: width, height: height)
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(isOn ? 0 : 0.10), lineWidth: 1)
        )
    }
}
