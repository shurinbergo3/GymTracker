//
//  BrandLogoView.swift
//  GymTracker
//
//  Brand mark for BODY FORGE — uses the official app logo asset wrapped in
//  atmospheric glow, geometric frame and corner ticks.
//

import SwiftUI

// MARK: - Geometric Frame
/// Восьмиугольная огранка вокруг логотипа.
struct ForgeMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cut = w * 0.22

        path.move(to: CGPoint(x: cut, y: 0))
        path.addLine(to: CGPoint(x: w - cut, y: 0))
        path.addLine(to: CGPoint(x: w, y: cut))
        path.addLine(to: CGPoint(x: w, y: h - cut))
        path.addLine(to: CGPoint(x: w - cut, y: h))
        path.addLine(to: CGPoint(x: cut, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - cut))
        path.addLine(to: CGPoint(x: 0, y: cut))
        path.closeSubpath()
        return path
    }
}

// MARK: - BrandLogoView

struct BrandLogoView: View {
    /// Размер картинки логотипа (квадрат)
    var size: CGFloat = 132
    /// Показывать ли надпись "BODY FORGE" под маркой
    var showWordmark: Bool = true
    /// Анимация пульсации halo
    var animated: Bool = true
    /// Показывать ли декоративную огранку-рамку вокруг лого
    var showFrame: Bool = true

    @State private var pulse: Bool = false

    private let neon = DesignSystem.Colors.neonGreen

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                // Внешнее радиальное свечение
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [neon.opacity(0.5), neon.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.95
                        )
                    )
                    .frame(width: size * 1.9, height: size * 1.9)
                    .blur(radius: 32)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .opacity(pulse ? 0.95 : 0.65)

                if showFrame {
                    // Внешняя огранка
                    ForgeMark()
                        .stroke(neon.opacity(0.35), lineWidth: 1.2)
                        .frame(width: size * 1.18, height: size * 1.18)

                    // Угловые tick-маркеры
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(neon)
                            .frame(width: 10, height: 2)
                            .offset(x: size * 0.62)
                            .rotationEffect(.degrees(Double(i) * 90))
                    }
                }

                // Сам логотип-картинка
                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: neon.opacity(0.55), radius: 20)
                    .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
            }
            .frame(width: size * 1.5, height: size * 1.5)

            if showWordmark {
                VStack(spacing: 6) {
                    Text("BODY FORGE")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: neon.opacity(0.25), radius: 12)

                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(neon.opacity(0.6))
                            .frame(width: 22, height: 1)
                        Text("FORGE YOUR BODY")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .tracking(4)
                            .foregroundColor(neon.opacity(0.9))
                        Rectangle()
                            .fill(neon.opacity(0.6))
                            .frame(width: 22, height: 1)
                    }
                }
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Atmospheric Background

struct AtmosphericBackground: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    DesignSystem.Colors.neonGreen.opacity(0.18),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    DesignSystem.Colors.neonGreen.opacity(0.10),
                    Color.clear
                ],
                center: .init(x: 0.85, y: 0.95),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            GridOverlay()
                .stroke(Color.white.opacity(0.025), lineWidth: 0.5)
                .ignoresSafeArea()
        }
    }
}

private struct GridOverlay: Shape {
    var spacing: CGFloat = 28
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x: CGFloat = 0
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y < rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }
        return path
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()
        BrandLogoView()
    }
}
