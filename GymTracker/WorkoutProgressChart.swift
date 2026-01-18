// 
//  WorkoutProgressChart.swift
//  Workout Tracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Charts

struct WorkoutProgressBanner: View {
    let programName: String
    let program: Program?
    @Query private var allSessions: [WorkoutSession]
    
    // All completed sessions for this program
    private var programSessions: [WorkoutSession] {
        allSessions
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
    }
    
    // Chart data for last 7-10 workouts
    private var chartData: [(date: Date, volume: Double)] {
        programSessions
            .suffix(10)
            .map { session in
                let totalVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                return (date: session.date, volume: totalVolume)
            }
    }
    
    // Progress state based on last two sessions
    private var progressState: ProgressState {
        let lastTwo = programSessions.suffix(2)
        guard lastTwo.count >= 2 else { return .new }
        
        let latest = lastTwo.last!
        let previous = Array(lastTwo)[0]
        
        let latestVolume = latest.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        let previousVolume = previous.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
        
        if latestVolume > previousVolume {
            return .improved
        } else if latestVolume < previousVolume {
            return .declined
        } else {
            return .same
        }
    }
    
    private var totalWorkouts: Int {
        programSessions.count
    }
    
    var body: some View {
        Group {
            if let program = program {
                NavigationLink(destination: ProgramDetailView(program: program)) {
                    bannerContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                bannerContent
            }
        }
    }
    
    private var bannerContent: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("ПРОГРАММА")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Text(programName)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("\(totalWorkouts) тренировок")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            if programSessions.count >= 2 {
                                Text("•")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: progressState.icon)
                                        .font(.caption)
                                        .foregroundColor(progressState.color)
                                    
                                    Text(progressText)
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(progressState.color)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow icon for navigation hint
                    Image(systemName: "arrow.up.forward.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.neonGreen)
                }
                
                // Chart
                if !chartData.isEmpty {
                    ZStack {
                        // Background gradient
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
                        
                        // Chart
                        Chart {
                            ForEach(Array(chartData.enumerated()), id: \.offset) { index, item in
                                LineMark(
                                    x: .value("Workout", index),
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
                                    x: .value("Workout", index),
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
                                    x: .value("Workout", index),
                                    y: .value("Volume", item.volume)
                                )
                                .foregroundStyle(DesignSystem.Colors.neonGreen)
                                .symbolSize(30)
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .frame(height: 80)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                    }
                    .frame(height: 80)
                } else {
                    // Empty state
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.cardBackground.opacity(0.5))
                        
                        Text("Начни тренироваться")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(height: 80)
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
    
    private var progressText: String {
        switch progressState {
        case .improved: return "Прогресс"
        case .declined: return "Снижение"
        case .same: return "Стабильно"
        case .new: return "Первая"
        }
    }
    
    private var progressIconLarge: String {
        switch progressState {
        case .improved: return "arrow.up.right.circle.fill"
        case .declined: return "arrow.down.right.circle.fill"
        case .same: return "equal.circle.fill"
        case .new: return "star.circle.fill"
        }
    }
}

// MARK: - Full Progress Chart (для истории)

struct WorkoutProgressChart: View {
    let sessions: [WorkoutSession]
    
    // Filter sessions for the last 1 month
    private var filteredSessions: [WorkoutSession] {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return sessions
            .filter { $0.isCompleted && $0.date >= oneMonthAgo }
            .sorted { $0.date < $1.date }
    }
    
    // Chart Data
    private var chartData: [(date: Date, volume: Double)] {
        filteredSessions.map { session in
            let totalVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return (date: session.date, volume: totalVolume)
        }
    }
    
    // Trend Logic
    private var isGrowing: Bool {
        guard let first = chartData.first, let last = chartData.last, chartData.count > 1 else { return true }
        return last.volume >= first.volume
    }
    
    @State private var showingDetail = false

    var body: some View {
        if !chartData.isEmpty {
            Button(action: { showingDetail = true }) {
                PremiumBentoCard {
                VStack(alignment: .leading, spacing: 12) {
                     // Header
                     HStack {
                         Image(systemName: "chart.line.uptrend.xyaxis")
                             .foregroundStyle(isGrowing ? DesignSystem.Colors.neonGreen : .red)
                         Text("Показатель роста")
                             .font(.headline)
                             .foregroundStyle(.white)
                         
                         Spacer()
                         
                         // Arrow Indicator
                         Image(systemName: isGrowing ? "arrow.up.right" : "arrow.down.right")
                             .font(.title2)
                             .bold()
                             .foregroundStyle(isGrowing ? DesignSystem.Colors.neonGreen : .red)
                     }
                     
                     Spacer()
                     
                     HStack(alignment: .center, spacing: 16) {
                         // Chart
                         Chart {
                             ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                                 LineMark(
                                     x: .value("Date", index),
                                     y: .value("Volume", data.volume)
                                 )
                                 .foregroundStyle(
                                     LinearGradient(
                                         colors: [
                                             isGrowing ? DesignSystem.Colors.neonGreen : .red,
                                             (isGrowing ? DesignSystem.Colors.neonGreen : .red).opacity(0.3)
                                         ],
                                         startPoint: .leading,
                                         endPoint: .trailing
                                     )
                                 )
                                 .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                 .interpolationMethod(.catmullRom)
                             }
                         }
                         .chartXAxis(.hidden)
                         .chartYAxis(.hidden)
                         .frame(height: 50)
                         
                         // Description
                         VStack(alignment: .trailing) {
                             Text(isGrowing ? "Рост\nпоказателей" : "Снижение\nпоказателей")
                                 .font(.caption)
                                 .fontWeight(.bold)
                                 .foregroundStyle(isGrowing ? DesignSystem.Colors.neonGreen : .red)
                                 .multilineTextAlignment(.trailing)
                             
                             Text("\(filteredSessions.count) тренировок")
                                 .font(.caption2)
                                 .foregroundStyle(.gray)
                         }
                         .frame(width: 100, alignment: .trailing)
                     }
                     
                     Spacer()
                 }
            }
            .frame(height: 150)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingDetail) {
                ProgressDetailView()
            }
        }
    }
}

#Preview {
    VStack {
        WorkoutProgressBanner(programName: "PPL Program", program: nil)
            .modelContainer(for: [WorkoutSession.self], inMemory: true)
        
        Spacer()
    }
    .background(DesignSystem.Colors.background)
}
