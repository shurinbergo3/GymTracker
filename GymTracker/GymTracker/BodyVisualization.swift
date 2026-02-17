//
//  BodyVisualization.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI

struct BodyVisualizationView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DesignSystem.Colors.neonGreen.opacity(0.1),
                    DesignSystem.Colors.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(DesignSystem.CornerRadius.large)
            
            // Body silhouette with muscle groups
            Canvas { context, size in
                let centerX = size.width / 2
                let scale = min(size.width, size.height) / 200
                
                // Head
                let headPath = Circle()
                    .path(in: CGRect(
                        x: centerX - 15 * scale,
                        y: 10 * scale,
                        width: 30 * scale,
                        height: 30 * scale
                    ))
                context.fill(headPath, with: .color(DesignSystem.Colors.neonGreen.opacity(0.3)))
                context.stroke(headPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 2)
                
                // Neck
                var neckPath = Path()
                neckPath.move(to: CGPoint(x: centerX, y: 40 * scale))
                neckPath.addLine(to: CGPoint(x: centerX, y: 55 * scale))
                context.stroke(neckPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 3 * scale)
                
                // Shoulders
                var shouldersPath = Path()
                shouldersPath.move(to: CGPoint(x: centerX - 40 * scale, y: 60 * scale))
                shouldersPath.addLine(to: CGPoint(x: centerX + 40 * scale, y: 60 * scale))
                context.stroke(shouldersPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 8 * scale)
                
                // Chest
                let chestPath = Ellipse()
                    .path(in: CGRect(
                        x: centerX - 30 * scale,
                        y: 60 * scale,
                        width: 60 * scale,
                        height: 40 * scale
                    ))
                context.fill(chestPath, with: .color(DesignSystem.Colors.neonGreen.opacity(0.2)))
                context.stroke(chestPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 2)
                
                // Torso
                var torsoPath = Path()
                torsoPath.move(to: CGPoint(x: centerX - 30 * scale, y: 100 * scale))
                torsoPath.addLine(to: CGPoint(x: centerX - 25 * scale, y: 140 * scale))
                torsoPath.addLine(to: CGPoint(x: centerX + 25 * scale, y: 140 * scale))
                torsoPath.addLine(to: CGPoint(x: centerX + 30 * scale, y: 100 * scale))
                torsoPath.closeSubpath()
                context.fill(torsoPath, with: .color(DesignSystem.Colors.accent.opacity(0.15)))
                context.stroke(torsoPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 2)
                
                // Left Arm
                drawArm(context: context, centerX: centerX, scale: scale, left: true)
                
                // Right Arm
                drawArm(context: context, centerX: centerX, scale: scale, left: false)
                
                // Left Leg
                drawLeg(context: context, centerX: centerX, scale: scale, left: true)
                
                // Right Leg
                drawLeg(context: context, centerX: centerX, scale: scale, left: false)
                
                // Core/Abs
                drawAbs(context: context, centerX: centerX, scale: scale)
            }
            .aspectRatio(0.5, contentMode: .fit)
        }
    }
    
    private func drawArm(context: GraphicsContext, centerX: CGFloat, scale: CGFloat, left: Bool) {
        let side: CGFloat = left ? -1 : 1
        
        // Shoulder
        let shoulderPath = Circle()
            .path(in: CGRect(
                x: centerX + (side * 40 * scale) - 8 * scale,
                y: 55 * scale,
                width: 16 * scale,
                height: 16 * scale
            ))
        context.fill(shoulderPath, with: .color(DesignSystem.Colors.accent.opacity(0.3)))
        context.stroke(shoulderPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 2)
        
        // Bicep
        var bicepPath = Path()
        bicepPath.move(to: CGPoint(x: centerX + (side * 40 * scale), y: 70 * scale))
        bicepPath.addQuadCurve(
            to: CGPoint(x: centerX + (side * 45 * scale), y: 100 * scale),
            control: CGPoint(x: centerX + (side * 48 * scale), y: 85 * scale)
        )
        context.stroke(bicepPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 6 * scale)
        
        // Forearm
        var forearmPath = Path()
        forearmPath.move(to: CGPoint(x: centerX + (side * 45 * scale), y: 100 * scale))
        forearmPath.addLine(to: CGPoint(x: centerX + (side * 50 * scale), y: 130 * scale))
        context.stroke(forearmPath, with: .color(DesignSystem.Colors.neonGreen), lineWidth: 4 * scale)
    }
    
    private func drawLeg(context: GraphicsContext, centerX: CGFloat, scale: CGFloat, left: Bool) {
        let side: CGFloat = left ? -1 : 1
        
        // Quad
        var quadPath = Path()
        quadPath.move(to: CGPoint (x: centerX + (side * 15 * scale), y: 140 * scale))
        quadPath.addQuadCurve(
            to: CGPoint(x: centerX + (side * 18 * scale), y: 185 * scale),
            control: CGPoint(x: centerX + (side * 20 * scale), y: 160 * scale)
        )
        context.stroke(quadPath, with: .color(DesignSystem.Colors.accent), lineWidth: 8 * scale)
        
        // Calf
        var calfPath = Path()
        calfPath.move(to: CGPoint(x: centerX + (side * 18 * scale), y: 185 * scale))
        calfPath.addLine(to: CGPoint(x: centerX + (side * 20 * scale), y: 220 * scale))
        context.stroke(calfPath, with: .color(DesignSystem.Colors.accent), lineWidth: 5 * scale)
    }
    
    private func drawAbs(context: GraphicsContext, centerX: CGFloat, scale: CGFloat) {
        // 6-pack representation
        for row in 0..<3 {
            for col in 0..<2 {
                let x = centerX + (col == 0 ? -10 : 10) * scale - 6 * scale
                let y = 105 * scale + CGFloat(row) * 12 * scale
                
                let abPath = RoundedRectangle(cornerRadius: 3 * scale)
                    .path(in: CGRect(
                        x: x,
                        y: y,
                        width: 12 * scale,
                        height: 10 * scale
                    ))
                context.fill(abPath, with: .color(DesignSystem.Colors.neonGreen.opacity(0.25)))
                context.stroke(abPath, with: .color(DesignSystem.Colors.neonGreen.opacity(0.6)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Weight Chart

struct WeightChartView: View {
    let weightHistory: [WeightRecord]
    
    private var sortedHistory: [WeightRecord] {
        weightHistory.sorted { $0.date < $1.date }
    }
    
    private var minWeight: Double {
        sortedHistory.map { $0.weight }.min() ?? 0
    }
    
    private var maxWeight: Double {
        sortedHistory.map { $0.weight }.max() ?? 100
    }
    
    var body: some View {
        ZStack {
            if sortedHistory.count < 2 {
                // Not enough data
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                    
                    Text("Добавьте больше записей\nдля отображения графика".localized())
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
            } else {
                Canvas { context, size in
                    let padding: CGFloat = 10
                    let chartWidth = size.width - padding * 2
                    let chartHeight = size.height - padding * 2
                    
                    let weightRange = maxWeight - minWeight
                    let stepX = chartWidth / CGFloat(sortedHistory.count - 1)
                    
                    // Draw gradient background
                    var gradientPath = Path()
                    gradientPath.move(to: CGPoint(x: padding, y: size.height - padding))
                    
                    for (index, record) in sortedHistory.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let normalizedWeight = (record.weight - minWeight) / weightRange
                        let y = size.height - padding - (normalizedWeight * chartHeight)
                        
                        if index == 0 {
                            gradientPath.move(to: CGPoint(x: x, y: y))
                        } else {
                            gradientPath.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    gradientPath.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
                    gradientPath.addLine(to: CGPoint(x: padding, y: size.height - padding))
                    gradientPath.closeSubpath()
                    
                    context.fill(
                        gradientPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                DesignSystem.Colors.neonGreen.opacity(0.3),
                                DesignSystem.Colors.neonGreen.opacity(0.05)
                            ]),
                            startPoint: CGPoint(x: size.width / 2, y: 0),
                            endPoint: CGPoint(x: size.width / 2, y: size.height)
                        )
                    )
                    
                    // Draw line
                    var linePath = Path()
                    for (index, record) in sortedHistory.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let normalizedWeight = (record.weight - minWeight) / weightRange
                        let y = size.height - padding - (normalizedWeight * chartHeight)
                        
                        if index == 0 {
                            linePath.move(to: CGPoint(x: x, y: y))
                        } else {
                            linePath.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    context.stroke(
                        linePath,
                        with: .color(DesignSystem.Colors.neonGreen),
                        lineWidth: 3
                    )
                    
                    // Draw points
                    for (index, record) in sortedHistory.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let normalizedWeight = (record.weight - minWeight) / weightRange
                        let y = size.height - padding - (normalizedWeight * chartHeight)
                        
                        let dotPath = Circle()
                            .path(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
                        
                        context.fill(dotPath, with: .color(DesignSystem.Colors.neonGreen))
                        context.stroke(dotPath, with: .color(DesignSystem.Colors.cardBackground), lineWidth: 2)
                    }
                }
                .frame(height: 100)
            }
        }
    }
}

#Preview {
    VStack {
        BodyVisualizationView()
            .frame(height: 300)
        
        WeightChartView(weightHistory: [])
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
