//
//  ProgressDetailView.swift
//  GymTracker
//
//  Created by Antigravity
//

import SwiftUI
import SwiftData
import Charts

struct ProgressDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse)
    var allSessions: [WorkoutSession]
    
    @State private var selectedPeriod: StatsPeriod = .month
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case quarter = "3 месяца"
        case year = "Год"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    private var filteredSessions: [WorkoutSession] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date())!
        return allSessions.filter { $0.date >= cutoffDate && $0.isCompleted }
    }
    
    private var chartData: [(date: Date, volume: Double)] {
        filteredSessions.reversed().map { session in
            let totalVolume = session.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            return (date: session.date, volume: totalVolume)
        }
    }
    
    private var trendDirection: TrendDirection {
        guard chartData.count >= 2 else { return .stable }
        
        let firstHalf = chartData.prefix(chartData.count / 2)
        let secondHalf = chartData.suffix(chartData.count / 2)
        
        let firstAvg = firstHalf.map { $0.volume }.reduce(0, +) / Double(max(1, firstHalf.count))
        let secondAvg = secondHalf.map { $0.volume }.reduce(0, +) / Double(max(1, secondHalf.count))
        
        let changePercent = ((secondAvg - firstAvg) / max(1, firstAvg)) * 100
        
        if changePercent > 10 {
            return .strongUp
        } else if changePercent > 3 {
            return .up
        } else if changePercent > -3 {
            return .stable
        } else if changePercent > -10 {
            return .down
        } else {
            return .strongDown
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    periodSelector
                    
                    // Main Trend Indicator
                    trendIndicatorCard
                    
                    // Volume Chart
                    volumeChartSection
                    
                    // Statistics Grid
                    statsGrid
                    
                    // Arrow Legend
                    arrowLegendSection
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle("Статистика прогресса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button(action: { withAnimation { selectedPeriod = period } }) {
                    Text(period.rawValue)
                        .font(.caption)
                        .fontWeight(selectedPeriod == period ? .bold : .medium)
                        .foregroundColor(selectedPeriod == period ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ?
                            DesignSystem.Colors.neonGreen :
                            Color.white.opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    // MARK: - Trend Indicator Card
    private var trendIndicatorCard: some View {
        VStack(spacing: 16) {
            // Large Arrow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [trendDirection.color.opacity(0.3), trendDirection.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: trendDirection.arrowName)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(trendDirection.color)
                    .rotationEffect(.degrees(trendDirection.rotation))
            }
            
            // Trend Text
            VStack(spacing: 4) {
                Text(trendDirection.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(trendDirection.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Volume Chart
    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Объём тренировок")
                .font(.headline)
                .foregroundColor(.white)
            
            if chartData.isEmpty {
                Text("Недостаточно данных")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, data in
                        AreaMark(
                            x: .value("Тренировка", index),
                            y: .value("Объём", data.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [trendDirection.color.opacity(0.5), trendDirection.color.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Тренировка", index),
                            y: .value("Объём", data.volume)
                        )
                        .foregroundStyle(trendDirection.color)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Тренировка", index),
                            y: .value("Объём", data.volume)
                        )
                        .foregroundStyle(trendDirection.color)
                        .symbolSize(index == chartData.count - 1 ? 80 : 30)
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Тренировок", value: "\(filteredSessions.count)", icon: "figure.strengthtraining.traditional", color: .blue)
            statCard(title: "Общий объём", value: formatVolume(totalVolume), icon: "scalemass.fill", color: .purple)
            statCard(title: "Средний объём", value: formatVolume(avgVolume), icon: "chart.bar.fill", color: .orange)
            statCard(title: "Лучшая", value: formatVolume(bestVolume), icon: "star.fill", color: .yellow)
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Arrow Legend
    private var arrowLegendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Что означают стрелки")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(TrendDirection.allCases, id: \.self) { direction in
                HStack(spacing: 16) {
                    Image(systemName: direction.arrowName)
                        .font(.title2)
                        .foregroundColor(direction.color)
                        .rotationEffect(.degrees(direction.rotation))
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(direction.legendTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(direction.legendDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                if direction != TrendDirection.allCases.last {
                    Divider().background(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    private var totalVolume: Double {
        chartData.reduce(0) { $0 + $1.volume }
    }
    
    private var avgVolume: Double {
        chartData.isEmpty ? 0 : totalVolume / Double(chartData.count)
    }
    
    private var bestVolume: Double {
        chartData.map { $0.volume }.max() ?? 0
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fк", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Trend Direction Enum

enum TrendDirection: CaseIterable {
    case strongUp, up, stable, down, strongDown
    
    var arrowName: String {
        switch self {
        case .strongUp: return "arrow.up"
        case .up: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .down: return "arrow.down.right"
        case .strongDown: return "arrow.down"
        }
    }
    
    var rotation: Double {
        switch self {
        case .strongUp: return 0
        case .up: return 0
        case .stable: return 0
        case .down: return 0
        case .strongDown: return 0
        }
    }
    
    var color: Color {
        switch self {
        case .strongUp: return DesignSystem.Colors.neonGreen
        case .up: return Color(red: 0.5, green: 0.9, blue: 0.3)
        case .stable: return .gray
        case .down: return .orange
        case .strongDown: return .red
        }
    }
    
    var title: String {
        switch self {
        case .strongUp: return "Отличный прогресс!"
        case .up: return "Хороший рост"
        case .stable: return "Стабильно"
        case .down: return "Небольшое снижение"
        case .strongDown: return "Требует внимания"
        }
    }
    
    var subtitle: String {
        switch self {
        case .strongUp: return "Ваши показатели значительно улучшились"
        case .up: return "Вы на правильном пути"
        case .stable: return "Показатели держатся на одном уровне"
        case .down: return "Попробуйте увеличить нагрузку"
        case .strongDown: return "Рекомендуем пересмотреть программу"
        }
    }
    
    var legendTitle: String {
        switch self {
        case .strongUp: return "Сильный рост (>10%)"
        case .up: return "Умеренный рост (3-10%)"
        case .stable: return "Стабильно (±3%)"
        case .down: return "Небольшое снижение (3-10%)"
        case .strongDown: return "Значительное снижение (>10%)"
        }
    }
    
    var legendDescription: String {
        switch self {
        case .strongUp: return "Отличная динамика! Продолжайте в том же духе"
        case .up: return "Хорошие результаты, есть прогресс"
        case .stable: return "Показатели стабильны, попробуйте увеличить нагрузку"
        case .down: return "Возможно, нужен отдых или корректировка программы"
        case .strongDown: return "Рекомендуем обратить внимание на восстановление"
        }
    }
}

#Preview {
    ProgressDetailView()
}
