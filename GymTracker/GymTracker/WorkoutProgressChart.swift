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
    
    // Optimized Query: Fetch only completed sessions, sorted reverse by date
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted == true }, sort: \WorkoutSession.date, order: .reverse)
    private var allSessions: [WorkoutSession]
    
    // All completed sessions for this program
    private var programSessions: [WorkoutSession] {
        allSessions
            .filter { $0.programName == programName }
            // Already sorted by query, but verification needs oldest first usually for charts?
            // Chart logic below uses .suffix(10) of .sorted { $0.date < $1.date }
            // So we need oldest first for the logic below, or we assume query order.
            .reversed() // Query is reverse (newest first), so reversed() gives oldest first
    }
    
    // Chart data for last 7-10 workouts
    private var chartData: [(date: Date, volume: Double)] {
        // programSessions is now oldest->newest
        programSessions
            .suffix(10)
            .map { session in
                return (date: session.date, volume: session.volume)
            }
    }
    
    // Progress state based on last two sessions
    private var progressState: ProgressState {
        let lastTwo = programSessions.suffix(2)
        guard lastTwo.count >= 2 else { return .new }
        
        let latest = lastTwo.last!
        let previous = Array(lastTwo)[0]
        
        let latestVolume = latest.volume
        let previousVolume = previous.volume
        
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
                        Text("Программа".localized().uppercased())
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .tracking(1.2)
                        
                        Text(programName)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text("\(totalWorkouts) \("тренировок".localized())")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            if programSessions.count >= 2 {
                                Text(verbatim: "•")
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
                        
                        Text("Начни тренироваться".localized())
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
        case .improved: return "Прогресс".localized()
        case .declined: return "Снижение".localized()
        case .same: return "Стабильно".localized()
        case .new: return "Первая".localized()
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
    
    @State private var chartData: [(date: Date, volume: Double)] = []
    @State private var isLoading = true
    @State private var showingDetail = false

    // Trend uses full session history — ProgressTrend.calculate queries date windows
    // spanning up to 4 weeks and needs data beyond the chart's last-20 slice.
    private var trend: ProgressTrend {
        ProgressTrend.calculate(from: sessions)
    }

    var body: some View {
        Group {
            if isLoading {
                // Placeholder while loading
                PremiumBentoCard {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(DesignSystem.Colors.neonGreen)
                        Spacer()
                    }
                }
                .frame(height: 150)
            } else if !chartData.isEmpty {
                Button(action: { showingDetail = true }) {
                    PremiumBentoCard {
                        VStack(alignment: .leading, spacing: 12) {
                             // Header
                             HStack {
                                 Image(systemName: "chart.line.uptrend.xyaxis")
                                     .foregroundStyle(trend.color)
                                 Text("Показатель роста".localized())
                                     .font(.headline)
                                     .foregroundStyle(.white)
                                 
                                 Spacer()
                                 
                                 // Arrow Indicator from unified ProgressTrend
                                 Image(systemName: trend.icon)
                                     .font(.title2)
                                     .bold()
                                     .foregroundStyle(trend.color)
                                     .rotationEffect(.degrees(trend.rotation))
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
                                                     trend.color,
                                                     trend.color.opacity(0.3)
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
                                 
                                 // Description from unified ProgressTrend
                                 VStack(alignment: .trailing) {
                                     Text(trend.title)
                                         .font(.caption)
                                         .fontWeight(.bold)
                                         .foregroundStyle(trend.color)
                                         .multilineTextAlignment(.trailing)
                                     
                                     Text("\(chartData.count) \("тренировок".localized())")
                                         .font(.caption2)
                                         .foregroundStyle(.gray)
                                 }
                                 .frame(width: 100, alignment: .trailing)
                             }
                             
                             Spacer()
                         }
                    }
                    .frame(height: 150)
                    .contentShape(Rectangle()) // Ensure tap target
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingDetail) {
                    ProgressHubView()
                }
            }
        }
        .task(id: sessions.count) {
             await calculateChartData()
        }
    }
    
    private func calculateChartData() async {
        // Run on background thread to avoid blocking UI with set loading/volume calc
        
        // RELAXED FILTER: Take last 20 sessions regardless of date (and don't filter strict completion as we might be in the completion screen)
        // This ensures the graph shows data even if the user hasn't worked out in a while OR if it's the current just-finished session
        let relevantSessions = sessions
            // .filter { $0.isCompleted } // <-- REMOVED to show current session
            .sorted { $0.date < $1.date }
            .suffix(20)

        var results: [(Date, Double)] = []
        for session in relevantSessions {
            results.append((session.date, session.volume))
        }

        self.chartData = results
        self.isLoading = false
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
