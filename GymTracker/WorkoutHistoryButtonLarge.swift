import SwiftUI
import SwiftData
import Charts

struct WorkoutHistoryButtonLarge: View {
    @Query private var allSessions: [WorkoutSession]
    
    private var recentWorkouts: [WorkoutSession] {
        allSessions
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map { $0 }
    }
    
    private var chartData: [(date: String, volume: Double)] {
        recentWorkouts.enumerated().map { index, session in
            let totalVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return (date: "\(index)", volume: totalVolume)
        }
    }
    
    var body: some View {
        NavigationLink(destination: WorkoutHistoryView()) {
            CardView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("История тренировок")
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Твой прогресс и рекорды")
                                .font(DesignSystem.Typography.callout())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Arrow indicator
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                    
                    // Mini chart area
                    if !chartData.isEmpty {
                        ZStack {
                            // Chart background with gradient
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DesignSystem.Colors.neonGreen.opacity(0.15),
                                            DesignSystem.Colors.background.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 100)
                            
                            // Chart using Charts framework
                            Chart {
                                ForEach(Array(chartData.enumerated()), id: \.offset) { index, item in
                                    LineMark(
                                        x: .value("Day", index),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [DesignSystem.Colors.neonGreen, DesignSystem.Colors.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                    
                                    AreaMark(
                                        x: .value("Day", index),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.neonGreen.opacity(0.3),
                                                DesignSystem.Colors.neonGreen.opacity(0.05)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    
                                    PointMark(
                                        x: .value("Day", index),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(DesignSystem.Colors.neonGreen)
                                    .symbolSize(40)
                                }
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .frame(height: 100)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    } else {
                        // Empty state
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
                                .frame(height: 100)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 32))
                                    .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                                
                                Text("Начни тренироваться")
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
