//  CountdownView.swift
//  GymTracker
//
//  Tactical Power-Up HUD: layered energy waves, segmented power meter,
//  chromatic glow, particle bursts and a screen flash on launch.
//

import SwiftUI
import AudioToolbox

struct CountdownView: View {
    var dayName: String? = nil
    var onComplete: () -> Void

    private let totalSteps = 3

    @State private var count: Int = 3
    @State private var ringProgress: CGFloat = 0.0
    @State private var numberScale: CGFloat = 0.4
    @State private var numberOpacity: Double = 0.0
    @State private var glitchOffset: CGFloat = 0
    @State private var pulse: CGFloat = 0
    @State private var rotateBg: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var bursts: [BurstParticle] = []
    @State private var didStart: Bool = false
    @State private var finished: Bool = false

    private var displayDayName: String {
        dayName ?? String(localized: "Тренировка")
    }

    private var motivation: String {
        switch count {
        case 3: return String(localized: "Дыши. Сфокусируйся.")
        case 2: return String(localized: "Заряжайся.")
        case 1: return String(localized: "Взрыв энергии.")
        default: return String(localized: "Поехали!")
        }
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.neonGreen.opacity(0.0),
                DesignSystem.Colors.neonGreen.opacity(0.4),
                DesignSystem.Colors.neonGreen,
                Color.cyan.opacity(0.9),
                DesignSystem.Colors.neonGreen
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            backgroundLayer
            energyWaves
            centerStack
            hudOverlay
            flashLayer
            particleLayer
        }
        .onAppear { if !didStart { didStart = true; startSequence() } }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            // Radial neon glow pulse
            RadialGradient(
                colors: [
                    DesignSystem.Colors.neonGreen.opacity(0.22),
                    DesignSystem.Colors.neonGreen.opacity(0.04),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 380
            )
            .scaleEffect(1 + pulse * 0.08)
            .opacity(0.7 + Double(pulse) * 0.3)
            .ignoresSafeArea()

            // Slow rotating conic accent
            AngularGradient(
                colors: [
                    .clear,
                    DesignSystem.Colors.neonGreen.opacity(0.08),
                    .clear,
                    Color.cyan.opacity(0.06),
                    .clear
                ],
                center: .center
            )
            .blendMode(.screen)
            .rotationEffect(.degrees(rotateBg))
            .ignoresSafeArea()

            // Subtle scanlines
            ScanlineOverlay()
                .opacity(0.06)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: - Energy Waves

    private var energyWaves: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        DesignSystem.Colors.neonGreen.opacity(0.18 - Double(i) * 0.05),
                        lineWidth: 1
                    )
                    .frame(width: 280 + CGFloat(i) * 70, height: 280 + CGFloat(i) * 70)
                    .scaleEffect(1 + pulse * (0.05 + CGFloat(i) * 0.02))
                    .opacity(1 - Double(pulse) * 0.4)
            }
        }
    }

    // MARK: - Center

    private var centerStack: some View {
        ZStack {
            // Segmented power meter (12 ticks)
            SegmentMeter(progress: ringProgress, segments: 12)
                .frame(width: 290, height: 290)
                .opacity(0.6)

            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 14)
                .frame(width: 230, height: 230)

            // Inner subtle gradient disk
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 230, height: 230)

            // Active progress ring with double glow
            if !finished {
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.7), radius: 18)
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.4), radius: 40)
            }

            // Tick marker dot at progress head
            if !finished && ringProgress > 0.02 {
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: DesignSystem.Colors.neonGreen, radius: 8)
                    .offset(y: -115)
                    .rotationEffect(.degrees(Double(ringProgress) * 360))
            }

            // Number / icon
            Group {
                if !finished {
                    NumberDisplay(
                        value: count,
                        scale: numberScale,
                        opacity: numberOpacity,
                        glitch: glitchOffset
                    )
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 90, weight: .black))
                        .foregroundStyle(DesignSystem.Colors.neonGreen)
                        .shadow(color: DesignSystem.Colors.neonGreen, radius: 24)
                        .scaleEffect(numberScale)
                        .opacity(numberOpacity)
                }
            }
        }
        .offset(y: -10)
    }

    // MARK: - HUD Overlay

    private var hudOverlay: some View {
        VStack {
            // Top tag
            HStack(spacing: 10) {
                Circle()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: 8, height: 8)
                    .shadow(color: DesignSystem.Colors.neonGreen, radius: 6)
                    .opacity(0.5 + Double(pulse) * 0.5)

                Text("READY".localized())
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .tracking(4)
                    .foregroundStyle(DesignSystem.Colors.neonGreen)

                Rectangle()
                    .fill(DesignSystem.Colors.neonGreen.opacity(0.4))
                    .frame(width: 30, height: 1)

                Text(displayDayName.uppercased())
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(DesignSystem.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.top, 30)

            Spacer()

            // Bottom: motivation + phase indicator
            VStack(spacing: 14) {
                Text(motivation)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(1.2)
                    .multilineTextAlignment(.center)
                    .id("mot-\(count)") // re-trigger animation per step
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 14)),
                        removal: .opacity.combined(with: .offset(y: -14))
                    ))

                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        let active = (totalSteps - count) > i
                        Capsule()
                            .fill(active
                                ? DesignSystem.Colors.neonGreen
                                : Color.white.opacity(0.15))
                            .frame(width: active ? 28 : 14, height: 4)
                            .shadow(
                                color: active ? DesignSystem.Colors.neonGreen.opacity(0.8) : .clear,
                                radius: active ? 6 : 0
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: count)
                    }
                }

                Text("PHASE \(min(totalSteps - count + 1, totalSteps))/\(totalSteps)")
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 70)
        }
    }

    private var flashLayer: some View {
        Color.white
            .opacity(flashOpacity)
            .ignoresSafeArea()
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    private var particleLayer: some View {
        ZStack {
            ForEach(bursts) { p in
                Circle()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: p.size, height: p.size)
                    .shadow(color: DesignSystem.Colors.neonGreen, radius: 6)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Animation Sequence

    private func startSequence() {
        // Continuous background pulse
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulse = 1.0
        }
        // Slow background rotation
        withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
            rotateBg = 360
        }
        performCountStep(val: totalSteps)
    }

    private func performCountStep(val: Int) {
        guard val > 0 else { finish(); return }

        withAnimation(.easeInOut(duration: 0.35)) {
            count = val
        }
        numberScale = 0.5
        numberOpacity = 0.0
        ringProgress = 0.0
        glitchOffset = 4

        // Pop in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            numberScale = 1.15
            numberOpacity = 1.0
        }
        // Settle glitch
        withAnimation(.easeOut(duration: 0.25)) {
            glitchOffset = 0
        }
        // Ring fill
        withAnimation(.easeInOut(duration: 0.92)) {
            ringProgress = 1.0
        }

        // Subtle screen flash
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.18 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeIn(duration: 0.25)) { flashOpacity = 0 }
        }

        // Particle burst
        spawnBurst(intensity: val == 1 ? 18 : 10)

        // Haptics + sound
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        AudioServicesPlaySystemSound(1113)

        // Pop out before next
        withAnimation(.easeIn(duration: 0.2).delay(0.78)) {
            numberScale = 0.7
            numberOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            performCountStep(val: val - 1)
        }
    }

    private func finish() {
        count = 0
        finished = true
        numberScale = 0.4
        numberOpacity = 0

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            numberScale = 1.4
            numberOpacity = 1.0
        }

        // Big flash
        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = 0.5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.4)) { flashOpacity = 0 }
        }

        spawnBurst(intensity: 28)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            onComplete()
        }
    }

    private func spawnBurst(intensity: Int) {
        let new = (0..<intensity).map { _ in BurstParticle.random() }
        bursts.append(contentsOf: new)

        for p in new {
            withAnimation(.easeOut(duration: 0.9)) {
                if let idx = bursts.firstIndex(where: { $0.id == p.id }) {
                    bursts[idx].x = p.targetX
                    bursts[idx].y = p.targetY
                    bursts[idx].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            bursts.removeAll { p in new.contains(where: { $0.id == p.id }) }
        }
    }
}

// MARK: - Number with chromatic aberration

private struct NumberDisplay: View {
    let value: Int
    let scale: CGFloat
    let opacity: Double
    let glitch: CGFloat

    var body: some View {
        ZStack {
            // Chromatic offsets
            Text("\(value)")
                .font(.system(size: 150, weight: .black, design: .rounded))
                .foregroundStyle(Color.cyan.opacity(0.7))
                .blendMode(.screen)
                .offset(x: -glitch, y: 0)

            Text("\(value)")
                .font(.system(size: 150, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.5).opacity(0.7))
                .blendMode(.screen)
                .offset(x: glitch, y: 0)

            // Main neon
            Text("\(value)")
                .font(.system(size: 150, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            DesignSystem.Colors.neonGreen
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: DesignSystem.Colors.neonGreen, radius: 16)
                .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.5), radius: 40)
        }
        .scaleEffect(scale)
        .opacity(opacity)
    }
}

// MARK: - Segmented Power Meter

private struct SegmentMeter: View {
    let progress: CGFloat
    let segments: Int

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 6
            ZStack {
                ForEach(0..<segments, id: \.self) { i in
                    let segProgress = CGFloat(i) / CGFloat(segments)
                    let active = progress >= segProgress
                    Capsule()
                        .fill(active
                            ? DesignSystem.Colors.neonGreen
                            : Color.white.opacity(0.12))
                        .frame(width: 3, height: 14)
                        .shadow(
                            color: active ? DesignSystem.Colors.neonGreen : .clear,
                            radius: active ? 4 : 0
                        )
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(i) / Double(segments) * 360))
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Scanline overlay

private struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let step: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    ctx.fill(Path(rect), with: .color(.white.opacity(0.06)))
                    y += step
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Particle model

private struct BurstParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    var opacity: Double
    let size: CGFloat

    static func random() -> BurstParticle {
        let angle = Double.random(in: 0..<(2 * .pi))
        let distance = CGFloat.random(in: 120...240)
        return BurstParticle(
            x: 0, y: 0,
            targetX: CGFloat(cos(angle)) * distance,
            targetY: CGFloat(sin(angle)) * distance,
            opacity: 1.0,
            size: CGFloat.random(in: 3...7)
        )
    }
}

#Preview {
    CountdownView(dayName: "День 1 · Грудь / Трицепс", onComplete: {})
}
