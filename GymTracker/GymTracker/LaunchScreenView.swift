import SwiftUI

struct LaunchScreenView: View {
    var showLoader: Bool = true

    var body: some View {
        ZStack {
            // Тёмно-синий радиальный градиент — фон, который заполняет всё за картинкой.
            // Сверху чуть светлее (deep navy), к низу/краям — почти чёрный, чтобы лого светилось.
            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.16, blue: 0.30),  // deep navy
                    Color(red: 0.04, green: 0.07, blue: 0.16),  // midnight
                    Color(red: 0.01, green: 0.02, blue: 0.06)   // near-black
                ],
                center: .center,
                startRadius: 80,
                endRadius: 700
            )
            .ignoresSafeArea()

            // Картинка — .fit, чтобы вся помещалась без обрезки. Центрируется автоматически.
            GeometryReader { geo in
                Image("LaunchScreen")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .ignoresSafeArea()

            if showLoader {
                VStack {
                    Spacer()
                    NeonSpinner()
                        .frame(width: 56, height: 56)
                        .padding(.bottom, 80)
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Neon Spinner (iPhone-style 8-spoke + orbiting arc)

struct NeonSpinner: View {
    @State private var rotation: Double = 0
    @State private var arcRotation: Double = 0
    @State private var pulse: CGFloat = 0

    var body: some View {
        ZStack {
            // Soft glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.neonGreen.opacity(0.35),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .scaleEffect(1 + pulse * 0.15)
                .blur(radius: 4)

            // Apple-style 8 spokes with phased opacity
            ForEach(0..<8, id: \.self) { i in
                Capsule()
                    .fill(DesignSystem.Colors.neonGreen)
                    .frame(width: 4, height: 12)
                    .offset(y: -18)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .opacity(spokeOpacity(for: i))
                    .shadow(color: DesignSystem.Colors.neonGreen.opacity(0.8), radius: 3)
            }
            .rotationEffect(.degrees(rotation))

            // Orbiting cyan arc (counter-rotating)
            Circle()
                .trim(from: 0, to: 0.18)
                .stroke(
                    AngularGradient(
                        colors: [
                            .clear,
                            Color.cyan.opacity(0.9),
                            DesignSystem.Colors.neonGreen
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(arcRotation))
                .shadow(color: DesignSystem.Colors.neonGreen, radius: 6)
        }
        .onAppear { startAnimations() }
    }

    /// Apple's classic spinner: each spoke fades around the loop.
    /// We rotate the whole rig in 8 discrete steps by tying opacity
    /// to a continuous phase derived from `rotation`.
    private func spokeOpacity(for index: Int) -> Double {
        // Constant pattern — opacity falls off going backwards from "head".
        let head = 0
        let dist = (index - head + 8) % 8
        let levels: [Double] = [1.0, 0.85, 0.65, 0.5, 0.4, 0.3, 0.22, 0.15]
        return levels[dist]
    }

    private func startAnimations() {
        // Discrete 8-step rotation = classic iOS feel
        withAnimation(
            .linear(duration: 0.8).repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
        // Smooth opposing arc
        withAnimation(
            .linear(duration: 1.6).repeatForever(autoreverses: false)
        ) {
            arcRotation = -360
        }
        // Halo pulse
        withAnimation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        ) {
            pulse = 1.0
        }
    }
}

#Preview {
    LaunchScreenView()
}
