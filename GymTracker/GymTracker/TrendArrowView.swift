//
//  TrendArrowView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI

struct TrendArrowView: View {
    let trend: ProgressTrend
    var size: CGFloat = 160
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular Badge with Arrow
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                trend.color.opacity(0.3),
                                trend.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: trend.color.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Arrow Icon
                Image(systemName: trend.icon)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(trend.color)
                    .rotationEffect(.degrees(trend.rotation))
            }
            
            // Text Labels
            VStack(spacing: 4) {
                Text(trend.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(trend.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Compact Card Version

struct TrendCard: View {
    let trend: ProgressTrend
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            TrendArrowView(trend: trend, size: 140)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
}

#Preview("Surge") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()
        
        TrendCard(trend: .surge)
            .padding()
    }
}

#Preview("Growth") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()
        
        TrendCard(trend: .growth)
            .padding()
    }
}

#Preview("Maintenance") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()
        
        TrendCard(trend: .maintenance)
            .padding()
    }
}

#Preview("Decline") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()
        
        TrendCard(trend: .decline)
            .padding()
    }
}

#Preview("Loss") {
    ZStack {
        DesignSystem.Colors.background
            .ignoresSafeArea()
        
        TrendCard(trend: .loss)
            .padding()
    }
}
